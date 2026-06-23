package DBIO::SQLite::Storage;
# ABSTRACT: SQLite storage driver for DBIO

use strict;
use warnings;

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

__PACKAGE__->register_driver('SQLite' => __PACKAGE__);

use Context::Preserve 'preserve_context';
use DBIO::Util qw(file_path iv_size mkpath modver_gt_or_eq os_name sigwarn_silencer);
use DBIO::SQLite::Util qw(column_is_nullable);
use Scalar::Util 'looks_like_number';
use DBIO::Carp;
use Try::Tiny;
use File::Basename ();
use File::Copy ();
use POSIX ();
use namespace::clean;

__PACKAGE__->sql_maker_class('DBIO::SQLite::SQLMaker');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->datetime_parser_type ('DateTime::Format::SQLite');

# Must be defined AFTER `use namespace::clean` — a sub declared before it
# is wiped from the symbol table at end of compile, which would make
# DBIO::Schema/deploy fall back to the (unsupported) SQL::Translator path.
sub dbio_deploy_class { 'DBIO::SQLite::Deploy' }

sub sql_maker {
  my $self = shift;
  my $sm = $self->next::method(@_);
  # SQLite always uses double-quote identifier quoting — ensure it is
  # active even when the caller did not pass quote_names in connect_info.
  $sm->{quote_char} //= $self->sql_quote_char;
  $sm->{name_sep}   //= $self->sql_name_sep;
  $sm;
}

sub _dbh_columns_info_for {
  my ($self, $dbh, $table) = @_;

  my $result = $self->SUPER::_dbh_columns_info_for($dbh, $table) // {};

  # DBD::SQLite's column_info (and its prepared-statement NULLABLE fallback)
  # do not report is_nullable reliably -- PK columns come back as nullable,
  # and columns in unique constraints may also be wrong. PRAGMA table_info
  # is the authoritative source: notnull=1 means NOT NULL. Layer its truth
  # over the parent's result so that PK columns are correctly NOT NULL.
  my $quoted = $dbh->quote(do {
    # Strip any "schema." prefix the caller may have supplied.
    my $t = $table;
    $t =~ s/^.*\.//;
    $t;
  });
  my $sth = eval { $dbh->prepare(qq{PRAGMA table_info($quoted)}) };
  return $result unless $sth;
  $sth->execute;
  while (my $row = $sth->fetchrow_hashref) {
    my $col = $row->{name};
    next unless $col && exists $result->{$col};
    # PRIMARY KEY columns are logically NOT NULL even when the DDL did
    # not declare them as such (PRAGMA table_info reports notnull=0 for
    # them -- a SQLite quirk). column_is_nullable is the single source of
    # truth for that rule (shared with DBIO::SQLite::Introspect).
    $result->{$col}{is_nullable} =
      column_is_nullable($row->{notnull}, $row->{pk});
  }
  $sth->finish;

  return $result;
}



sub _determine_supports_multicolumn_in {
  ( shift->_server_info->{normalized_dbms_version} < '3.014' )
    ? 0
    : 1
}

sub backup {
  my ($self, $dir) = @_;
  $dir //= './';

  ## Where is the db file?
  my $dsn = $self->_dbi_connect_info()->[0];

  my $dbname = $1 if($dsn =~ /dbname=([^;]+)/);
  if(!$dbname)
  {
    $dbname = $1 if($dsn =~ /^dbi:SQLite:(.+)$/i);
  }
  $self->throw_exception("Cannot determine name of SQLite db file")
    if(!$dbname || !-f $dbname);

  my $file = File::Basename::basename($dbname);
  $file = POSIX::strftime("%Y-%m-%d-%H_%M_%S", localtime()) . $file;
  $file = "B$file" while(-f $file);

  mkpath($dir) unless -d $dir;
  my $backupfile = file_path($dir, $file);

  my $res = File::Copy::copy($dbname, $backupfile);
  $self->throw_exception("Backup failed! ($!)") if(!$res);

  return $backupfile;
}


sub _exec_svp_begin {
  my ($self, $name) = @_;

  $self->_dbh->do("SAVEPOINT $name");
}

sub _exec_svp_release {
  my ($self, $name) = @_;

  $self->_dbh->do("RELEASE SAVEPOINT $name");
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;

  $self->_dbh->do("ROLLBACK TO SAVEPOINT $name");

  # resync state for older DBD::SQLite (RT#67843)
  # https://github.com/DBD-SQLite/DBD-SQLite/commit/9b3cdbf
  if (
    ! modver_gt_or_eq('DBD::SQLite', '1.33')
      and
    $self->_dbh->FETCH('AutoCommit')
  ) {
    $self->_dbh->STORE('AutoCommit', 0);
    $self->_dbh->STORE('BegunWork', 1);
  }
}

sub _ping {
  my $self = shift;

  # Be extremely careful what we do here. SQLite is notoriously bad at
  # synchronizing its internal transaction state with {AutoCommit}
  # https://metacpan.org/source/ADAMK/DBD-SQLite-1.37/lib/DBD/SQLite.pm#L921
  # There is a function http://www.sqlite.org/c3ref/get_autocommit.html
  # but DBD::SQLite does not expose it (nor does it seem to properly use it)

  # Therefore only execute a "ping" when we have no other choice *AND*
  # scrutinize the thrown exceptions to make sure we are where we think we are
  my $dbh = $self->_dbh or return undef;
  return undef unless $dbh->FETCH('Active');
  return undef unless $dbh->ping;

  my $ping_fail;

  # older DBD::SQLite does not properly synchronize commit state between
  # the libsqlite and the $dbh
  unless (defined $DBD::SQLite::__DBIO_TXN_SYNC_SANE__) {
    $DBD::SQLite::__DBIO_TXN_SYNC_SANE__ = modver_gt_or_eq('DBD::SQLite', '1.38_02');
  }

  # fallback to travesty
  unless ($DBD::SQLite::__DBIO_TXN_SYNC_SANE__) {
    # since we do not have access to sqlite3_get_autocommit(), do a trick
    # to attempt to *safely* determine what state are we *actually* in.
    # FIXME
    # also using T::T here leads to bizarre leaks - will figure it out later
    my $really_not_in_txn = do {
      local $@;

      # older versions of DBD::SQLite do not properly detect multiline BEGIN/COMMIT
      # statements to adjust their {AutoCommit} state. Hence use such a statement
      # pair here as well, in order to escape from poking {AutoCommit} needlessly
      # https://rt.cpan.org/Public/Bug/Display.html?id=80087
      eval {
        # will fail instantly if already in a txn
        $dbh->do("-- multiline\nBEGIN");
        $dbh->do("-- multiline\nCOMMIT");
        1;
      } or do {
        ($@ =~ /transaction within a transaction/)
          ? 0
          : undef
        ;
      };
    };

    # if we were unable to determine this - we may very well be dead
    if (not defined $really_not_in_txn) {
      $ping_fail = 1;
    }
    # check the AC sync-state
    elsif ($really_not_in_txn xor $dbh->{AutoCommit}) {
      carp_unique (sprintf
        'Internal transaction state of handle %s (apparently %s a transaction) does not seem to '
      . 'match its AutoCommit attribute setting of %s - this is an indication of a '
      . 'potentially serious bug in your transaction handling logic',
        $dbh,
        $really_not_in_txn ? 'NOT in' : 'in',
        $dbh->{AutoCommit} ? 'TRUE' : 'FALSE',
      );

      # it is too dangerous to execute anything else in this state
      # assume everything works (safer - worst case scenario next statement throws)
      return 1;
    }
  }

  # do the actual test and return on no failure
  ( $ping_fail ||= ! try { $dbh->do('SELECT * FROM sqlite_master LIMIT 1'); 1 } )
    or return 1; # the actual RV of _ping()

  # ping failed (or so it seems) - need to do some cleanup
  # it is possible to have a proper "connection", and have "ping" return
  # false anyway (e.g. corrupted file). In such cases DBD::SQLite still
  # keeps the actual file handle open. We don't really want this to happen,
  # so force-close the handle via DBI itself
  #
  local $@; # so that we do not clobber the real error as set above
  eval { $dbh->disconnect }; # if it fails - it fails
  undef; # the actual RV of _ping()
}

sub bind_attribute_by_data_type {

  # According to http://www.sqlite.org/datatype3.html#storageclasses
  # all numeric types are dynamically allocated up to 8 bytes per
  # individual value
  # Thus it should be safe and non-wasteful to bind everything as
  # SQL_BIGINT and have SQLite deal with storage/comparisons however
  # it deems correct
  $_[1] =~ /^ (?: int(?:[1248]|eger)? | (?:tiny|small|medium|big)int ) $/ix
    ? DBI::SQL_BIGINT()
    : undef
  ;
}


# FIXME - what the flying fuck... work around RT#76395
# DBD::SQLite warns on binding >32 bit values with 32 bit IVs
sub _dbh_execute {
  if (
    (
      iv_size < 8
        or
      os_name eq 'MSWin32'
    )
      and
    ! defined $DBD::SQLite::__DBIO_CHECK_dbd_mishandles_bound_BIGINT
  ) {
    $DBD::SQLite::__DBIO_CHECK_dbd_mishandles_bound_BIGINT = (
      modver_gt_or_eq('DBD::SQLite', '1.37')
    ) ? 1 : 0;
  }

  local $SIG{__WARN__} = sigwarn_silencer( qr/
    \Qdatatype mismatch: bind\E \s (?:
      param \s+ \( \d+ \) \s+ [-+]? \d+ (?: \. 0*)? \Q as integer\E
        |
      \d+ \s type \s @{[ DBI::SQL_BIGINT() ]} \s as \s [-+]? \d+ (?: \. 0*)?
    )
  /x ) if (
    (
      iv_size < 8
        or
      os_name eq 'MSWin32'
    )
      and
    $DBD::SQLite::__DBIO_CHECK_dbd_mishandles_bound_BIGINT
  );

  shift->next::method(@_);
}

# DBD::SQLite (at least up to version 1.31 has a bug where it will
# non-fatally numify a string value bound as an integer, resulting
# in insertions of '0' into supposed-to-be-numeric fields
# Since this can result in severe data inconsistency, remove the
# bind attr if such a situation is detected
#
# FIXME - when a DBD::SQLite version is released that eventually fixes
# this situation (somehow) - no-op this override once a proper DBD
# version is detected
sub _dbi_attrs_for_bind {
  my ($self, $ident, $bind) = @_;

  my $bindattrs = $self->next::method($ident, $bind);

  if (! defined $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values) {
    $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values
      = modver_gt_or_eq('DBD::SQLite', '1.37') ? 1 : 0;
  }

  for my $i (0.. $#$bindattrs) {

    if (defined $bindattrs->[$i]) {
      # Validate existing integer bind attributes
      if (
        defined $bind->[$i][1]
          and
        grep { $bindattrs->[$i] eq $_ } (
          DBI::SQL_INTEGER(), DBI::SQL_TINYINT(), DBI::SQL_SMALLINT(), DBI::SQL_BIGINT()
        )
      ) {
        if ( $bind->[$i][1] !~ /^ [\+\-]? [0-9]+ (?: \. 0* )? $/x ) {
          carp_unique( sprintf (
            "Non-integer value supplied for column '%s' despite the integer datatype",
            $bind->[$i][0]{dbic_colname} || "# $i"
          ) );
          undef $bindattrs->[$i];
        }
        elsif (
          ! $DBD::SQLite::__DBIO_CHECK_dbd_can_bind_bigint_values
        ) {
          if ($bind->[$i][1] > 0x7fff_ffff or $bind->[$i][1] < -0x8000_0000) {
            carp_unique( sprintf (
              "An integer value occupying more than 32 bits was supplied for column '%s' "
            . 'which your version of DBD::SQLite (%s) can not bind properly so DBIO '
            . 'will treat it as a string instead, consider upgrading to at least '
            . 'DBD::SQLite version 1.37',
              $bind->[$i][0]{dbic_colname} || "# $i",
              DBD::SQLite->VERSION,
            ) );
            undef $bindattrs->[$i];
          }
          else {
            $bindattrs->[$i] = DBI::SQL_INTEGER()
          }
        }
      }
    }
    elsif (
      # SQLite binds all parameters as TEXT by default (sqlite3_bind_text).
      # This causes cross-type comparison failures: INTEGER < TEXT is always
      # true in SQLite's type sort order, so e.g. COUNT(x) > ? with a text
      # bind always returns FALSE. Fix by hinting numeric values as SQL_INTEGER
      # when no column-based type info is available.
      #
      # Apply to:
      # - Anonymous binds (no dbic_colname) from literal SQL
      # - Expression binds (colname contains parens, e.g. 'COUNT(x)')
      # Do NOT apply to plain column aliases (e.g. 'newest_cd_year') as
      # these may reference TEXT-typed columns containing numeric strings.
      defined $bind->[$i][1]
        and
      ! ref $bind->[$i][1]
        and
      looks_like_number($bind->[$i][1])
        and
      (
        ! $bind->[$i][0]{dbic_colname}
          or
        $bind->[$i][0]{dbic_colname} =~ /\(/  # expression (COUNT, MAX, etc.)
      )
    ) {
      $bindattrs->[$i] = DBI::SQL_INTEGER();
    }

  }

  return $bindattrs;
}

sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  my $txn_scope_guard = $self->txn_scope_guard;

  $self->_do_query('PRAGMA defer_foreign_keys = ON');

  return preserve_context { $sub->() } after => sub { $txn_scope_guard->commit };
}


sub connect_call_use_foreign_keys {
  my $self = shift;

  $self->_do_query(
    'PRAGMA foreign_keys = ON'
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Storage - SQLite storage driver for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

SQLite storage driver for DBIO. Extends L<DBIO::Storage::DBI> with
SQLite-specific behavior including savepoint support, foreign key pragma
helpers, database file backup, and workarounds for known L<DBD::SQLite> bugs.

This class is registered as the driver for C<SQLite> and is loaded
automatically when connecting to a SQLite DSN. It uses
L<DBIO::SQLite::SQLMaker> for SQL generation, C<LimitOffset> pagination,
double-quote identifiers, and L<DateTime::Format::SQLite> for datetime
parsing.

=head1 METHODS

=head2 _dbh_columns_info_for

Override the parent's C<column_info> lookup. DBD::SQLite does not
implement C<NULLABLE> correctly -- PRIMARY KEY columns and columns
constrained by C<UNIQUE ... NOT NULL> come back as nullable. This
override layers the truth from C<PRAGMA table_info> (C<notnull>) on
top of the parent method's result so that C<is_nullable> is correct
for downstream consumers like L<DBIO::Result/columns_info_for>.

=head2 backup

    my $backupfile = $storage->backup($dir);
    my $backupfile = $storage->backup;          # defaults to './'

Copy the live SQLite database file to C<$dir>. The backup filename includes
a timestamp prefix. Returns the full path to the backup file.

Throws an exception if the database filename cannot be determined from the
DSN or if the file copy fails.

=head2 bind_attribute_by_data_type

Returns C<DBI::SQL_BIGINT> for any integer-family column type (C<int>,
C<integer>, C<tinyint>, C<smallint>, C<mediumint>, C<bigint>, C<int1>,
C<int2>, C<int4>, C<int8>). Returns C<undef> for all other types, deferring
to the default binding behavior.

SQLite stores all numeric values as dynamically-sized integers up to 8 bytes,
so binding everything as C<SQL_BIGINT> is safe and avoids unnecessary type
coercions.

=head2 with_deferred_fk_checks

    $storage->with_deferred_fk_checks(sub { ... });

Execute C<$sub> inside a transaction with C<PRAGMA defer_foreign_keys = ON>.
Foreign key constraint checking is deferred until the transaction commits,
allowing bulk inserts or other operations that temporarily violate referential
integrity within the same transaction. The transaction is committed
automatically after C<$sub> returns.

=head2 connect_call_use_foreign_keys

A connect-time callback that executes C<PRAGMA foreign_keys = ON>. SQLite
does not enforce foreign key constraints by default. Enable it by passing
C<on_connect_call =E<gt> 'use_foreign_keys'> in your connection options:

    $schema->connect(
        'dbi:SQLite:db/app.db', '', '',
        { on_connect_call => 'use_foreign_keys' },
    );

=seealso

=over

=item * L<DBIO::SQLite> - Schema component that activates this storage

=item * L<DBIO::SQLite::SQLMaker> - SQL generation for SQLite

=item * L<DBIO::Storage::DBI> - Base DBI storage class

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
