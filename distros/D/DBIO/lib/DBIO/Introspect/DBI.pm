package DBIO::Introspect::DBI;
# ABSTRACT: DBI-based introspection via standard metadata APIs

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Introspect::Base/;
use DBI ();
use DBIO::Componentised ();
use Scalar::Util 'looks_like_number';
use namespace::clean;



sub dbms_name { $_[0]->{dbms_name} //= $_[0]->dbh->{Driver}->{Name} }


sub class_for_dbh {
  my ($class, $dbh) = @_;

  my $driver_name = eval { $dbh->{Driver}{Name} } or return $class;

  require DBIO::Storage::DBI;
  my $storage_class = DBIO::Storage::DBI->driver_storage_class($driver_name)
    or return $class;

  # DBIO::MySQL::Storage and DBIO::MySQL::Storage::MariaDB both live under
  # DBIO::MySQL. DBIO::Storage::DBI::ODBC would reduce to bare DBIO, which
  # owns no driver introspector -- that is the generic path by definition.
  (my $namespace = $storage_class) =~ s/::Storage(?:::.*)?\z//;
  return $class if $namespace eq 'DBIO' || $namespace eq $storage_class;

  my $candidate = "${namespace}::Introspect";

  # returns 0 when the .pm is simply not there, throws when it is there and
  # fails to compile -- the two cases deserve different treatment
  my $loaded = eval { DBIO::Componentised->load_optional_class($candidate) };
  unless (defined $loaded) {
    warn "$candidate is installed but failed to load: $@"
       . "Falling back to $class -- the generated classes will be less accurate.\n";
    return $class;
  }
  return $class unless $loaded;
  return $class unless $candidate->isa('DBIO::Introspect::Base');

  return $candidate;
}


sub table_keys {
  my ($self) = @_;
  my @tables;

  # DBI spec: $type is a comma-separated STRING, never an arrayref -- an
  # arrayref stringifies to "ARRAY(0x...)" and silently matches nothing.
  # Unquoted and whitespace-free is the form every driver reads correctly:
  # DBD::SQLite/Pg/Oracle split on ',' and add the quoting themselves (Pg does
  # not trim, so "TABLE, VIEW" would become ' VIEW' and match no row),
  # DBD::MariaDB/mysql only tests m/table/i and m/view/i, DBD::Firebird strips
  # quotes back off. The quoted form the spec also allows would break any
  # driver that compares the split values literally.
  my $sth = $self->dbh->table_info(undef, undef, '%', 'TABLE,VIEW');
  while (my $row = $sth->fetchrow_hashref) {
    my $schema = $row->{TABLE_SCHEM} // '';
    my $name   = $row->{TABLE_NAME} // next;

    # SQLite: only tables in main TEMP etc
    # Oracle: filter out system schemas
    if ($self->dbms_name eq 'Oracle' && $schema =~ /^(SYS|SYSTEM)/) {
      next;
    }

    my $key = $schema ? "${schema}.${name}" : $name;
    push @tables, $key;
  }
  $sth->finish;

  return \@tables;
}


sub table_columns {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  my $sth = $self->dbh->column_info($schema, undef, $table, '%');
  my @cols;
  my %seen;
  while (my $row = $sth->fetchrow_hashref) {
    my $col = $row->{COLUMN_NAME} // next;
    push @cols, $col unless $seen{$col}++;
  }
  $sth->finish;

  # DBI doesn't guarantee order, so query directly for known drivers
  if ($self->dbms_name eq 'SQLite') {
    (my $quoted = $table) =~ s/'/''/g;
    my $info = $self->dbh->prepare("PRAGMA table_info('$quoted')");
    $info->execute;
    @cols = ();
    %seen = ();
    while (my $row = $info->fetch) {
      push @cols, $row->[1] unless $seen{$row->[1]}++;
    }
  }

  return \@cols;
}


sub table_columns_info {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  # A primary-key column cannot hold NULL whatever the DBD says
  # about its NOT NULL attribute. The driver introspectors already fold this
  # in (DBIO::SQLite::Introspect::table_columns_info); the generic path is
  # what a user without the driver distribution gets, so it folds it in too
  # and both answer the same thing for the same database. ADR 0038.
  my %is_pk = map { $_ => 1 } @{ $self->table_pk_info($key) };

  my %cols;
  my $sth = $self->dbh->column_info($schema, undef, $table, '%');
  while (my $row = $sth->fetchrow_hashref) {
    my $col = $row->{COLUMN_NAME} // next;

    # The column's data_type is TYPE_NAME, the readable type name.
    # DATA_TYPE is the numeric SQL type code (SQL_INTEGER == 4) and used to be
    # what landed in the generated result class. TYPE_NAME is also what the
    # driver introspectors report, so the fallback path and the driver path now
    # answer the same thing; a private code->name table here would be a second
    # truth next to them and would drift.
    my $type_str = $row->{TYPE_NAME} // '';
    my $size = $row->{COLUMN_SIZE};

    # MySQL reports TEXT as varchar(65535)
    if ($type_str =~ /varchar/i && defined $size && $size == 65535) {
      $type_str = 'text';
    }

    # No type information at all. Keep generating -- a class with one guessed
    # column is more use than an aborted run -- but say so per column, because
    # the guess is indistinguishable from a real varchar once it is in the
    # emitted code.
    unless (length $type_str) {
      warn "$key.$col: this DBD reports no TYPE_NAME for the column, guessing"
        . " data_type => 'varchar'. Correct it in the generated class, or"
        . " install the DBIO driver distribution for this database -- its"
        . " introspector reads the native catalog instead of the generic DBI"
        . " metadata.\n";
      $type_str = 'varchar';
    }

    my $default = $row->{COLUMN_DEF};
    # Strip quotes from default values
    if (defined $default && $default =~ /^'(.*)'$/) {
      $default = $1;
    }

    my $auto_increment =
         ($row->{COLUMN_DEF} // '') =~ /nextval/i  # PostgreSQL serial
      || $row->{mysql_is_auto_increment}            # DBD::mysql / DBD::MariaDB
      ? 1 : 0;

    $cols{$col} = {
      data_type        => $type_str,
      type             => $type_str,
      size             => looks_like_number($size) ? $size : undef,
      is_nullable      => $self->_is_nullable($key, $col, $row->{NULLABLE},
                                              $is_pk{$col}),
      default_value    => $default,
      is_auto_increment => $auto_increment,
    };
  }
  $sth->finish;

  return \%cols;
}

# DBI NULLABLE: 0 = no, 1 = yes, 2 = unknown; a DBD may also leave
# the field out entirely, which says the same thing as 2.
#
# The primary key is asked first because it is knowledge, not a reading of the
# attribute: no engine lets a key column hold NULL, so there is nothing left to
# be unsure about and nothing to announce.
#
# "Unknown" then resolves to nullable. The two guesses are not symmetrical:
# is_nullable => 0 is a claim the generated class enforces before the statement
# is ever sent, so a wrong 0 rejects INSERTs the database would have taken and
# the error blames DBIO. A wrong 1 only declines to duplicate a constraint the
# engine already has -- the INSERT goes out and the database says no itself,
# accurately. Guessing toward the side the database can still correct is the
# same call made for the other unknowns on this path, and it
# warns for the same reason: an assumption baked into emitted code is invisible
# once the file is written.
sub _is_nullable {
  my ($self, $key, $col, $nullable, $is_pk) = @_;

  return 0 if $is_pk;

  if (!defined $nullable || $nullable == 2) {
    warn "$key.$col: this DBD reports no usable NULLABLE for the column,"
      . " assuming is_nullable => 1. Correct it in the generated class, or"
      . " install the DBIO driver distribution for this database -- its"
      . " introspector reads the native catalog instead of the generic DBI"
      . " metadata.\n";
    return 1;
  }

  return $nullable == 1 ? 1 : 0;
}


sub table_pk_info {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  my $sth = $self->dbh->primary_key_info($schema, undef, $table)
    or return [];
  my @rows;
  while (my $row = $sth->fetchrow_hashref) {
    push @rows, $row if defined $row->{COLUMN_NAME};
  }
  $sth->finish;

  # Composite keys: order by KEY_SEQ
  my @pk = map { $_->{COLUMN_NAME} }
           sort { ($a->{KEY_SEQ} // 0) <=> ($b->{KEY_SEQ} // 0) } @rows;

  return \@pk;
}


sub table_uniq_info {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  # Not all DBD drivers implement statistics_info
  my $sth = eval { $self->dbh->statistics_info(undef, $schema, $table, 1, 1) }
    or return [];

  # Group index rows: each row is one column of one index
  my (%idx_cols, @idx_order);
  while (my $row = $sth->fetchrow_hashref) {
    my $idx_name = $row->{INDEX_NAME} // next;
    my $col      = $row->{COLUMN_NAME} // next;
    next if $row->{NON_UNIQUE};

    push @idx_order, $idx_name unless $idx_cols{$idx_name};
    push @{ $idx_cols{$idx_name} }, [ $row->{ORDINAL_POSITION} // 0, $col ];
  }
  $sth->finish;

  my @uniq;
  for my $idx_name (@idx_order) {
    my @cols = map { $_->[1] } sort { $a->[0] <=> $b->[0] } @{ $idx_cols{$idx_name} };
    push @uniq, [ $idx_name, \@cols ];
  }

  return \@uniq;
}


sub table_fk_info {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  # Drivers without FK support return undef
  my $sth = $self->dbh->foreign_key_info(undef, undef, undef, undef, $schema, $table)
    or return [];

  # One row per FK column; group composite FKs by constraint name.
  # DBI allows two naming styles: SQL/CLI (UK_/FK_) and ODBC (PK/FK).
  my (%fk, @fk_order);
  while (my $row = $sth->fetchrow_hashref) {
    my $local_col  = $row->{FK_COLUMN_NAME} // $row->{FKCOLUMN_NAME} // next;
    my $remote_tab = $row->{UK_TABLE_NAME}  // $row->{PKTABLE_NAME} // next;
    my $fk_name    = $row->{FK_NAME} // $remote_tab;
    my $seq        = $row->{ORDINAL_POSITION} // $row->{KEY_SEQ} // 0;

    push @fk_order, $fk_name unless $fk{$fk_name};
    my $fk = $fk{$fk_name} //= {
      remote_table  => $remote_tab,
      remote_schema => $row->{UK_TABLE_SCHEM} // $row->{PKTABLE_SCHEM},
      cols          => [],
    };
    push @{ $fk->{cols} },
      [ $seq, $local_col, $row->{UK_COLUMN_NAME} // $row->{PKCOLUMN_NAME} ];
  }
  $sth->finish;

  my @fks;
  for my $fk_name (@fk_order) {
    my $fk = $fk{$fk_name};
    my @cols = sort { $a->[0] <=> $b->[0] } @{ $fk->{cols} };
    push @fks, {
      local_columns  => [ map { $_->[1] } @cols ],
      remote_table   => $fk->{remote_table},
      remote_schema  => $fk->{remote_schema},
      remote_columns => [ grep { defined } map { $_->[2] } @cols ],
      attrs          => {},
    };
  }

  return \@fks;
}


sub table_is_view {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  # comma-separated string, not an arrayref -- see table_keys
  my $sth = $self->dbh->table_info($schema, undef, $table, 'VIEW');
  my $row = $sth->fetchrow_hashref;
  $sth->finish;

  return $row ? 1 : 0;
}


sub view_definition {
  my ($self, $key) = @_;
  my ($schema, $table) = $self->_split_key($key);

  # Most DBI drivers don't support this, but SQLite does
  if ($self->dbms_name eq 'SQLite') {
    my $sth = $self->dbh->prepare("SELECT sql FROM sqlite_master WHERE type='view' AND name=?");
    $sth->execute($table);
    my $row = $sth->fetch;
    $sth->finish;
    return $row ? $row->[0] : undef;
  }

  return undef;
}

sub _split_key {
  my ($self, $key) = @_;
  if ($key =~ /^(.+)\.(.+)$/) {
    return ($1, $2);
  }
  return (undef, $key);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Introspect::DBI - DBI-based introspection via standard metadata APIs

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Introspect::DBI> wraps DBI metadata APIs (C<column_info>,
C<primary_key>, C<foreign_key_info>, C<table_info>) into the normalized
contract defined in L<DBIO::Introspect::Base>.

Driver-specific introspectors (L<DBIO::PostgreSQL::Introspect>,
L<DBIO::SQLite::Introspect>, etc.) inherit from this when they want to
override with native queries for accuracy or features.

=head1 ATTRIBUTES

=head2 dbms_name

The DBI driver name (e.g., C<Pg>, C<SQLite>, C<mysql>). Auto-detected
from C<dbh> if not provided.

=head1 METHODS

=head2 class_for_dbh

    my $class = DBIO::Introspect::DBI->class_for_dbh($dbh);
    my $intro = $class->new(dbh => $dbh);

The most accurate introspector class available for C<$dbh>: the installed
driver's own (C<DBIO::MySQL::Introspect>, C<DBIO::SQLite::Introspect>, ...)
if there is one, otherwise C<DBIO::Introspect::DBI> itself.

The driver is resolved through the one registry that already maps DBD names
to DBIO classes, L<DBIO::Storage::DBI/driver_storage_class> -- C<mysql>
gives C<DBIO::MySQL::Storage>, whose namespace C<DBIO::MySQL> gives
C<DBIO::MySQL::Introspect>. Only the class I<name> is taken from the
registry; the driver's storage stack is never loaded, so introspection does
not depend on the DBD-level machinery being usable.

The candidate is returned only if it loads and is a
L<DBIO::Introspect::Base>, so an unregistered DBD, an uninstalled driver
distribution or a class that does not honour the contract all fall back to
the generic path rather than failing the caller. A driver that I<is>
installed but does not compile is a broken installation, not an absent one:
it warns before falling back, because the generated classes will silently be
the less accurate ones.

The returned class is already loaded.

=head2 table_keys

Returns all tables and views as C<[schema.]table> strings.

=head2 table_columns

    my \@names = $intro->table_columns($key);

Ordered list of column names for C<$key>.

=head2 table_columns_info

    my $info = $intro->table_columns_info($key);

Hashref C<{ col_name => { data_type, size, is_nullable, default_value,
is_auto_increment, ... } }>.

C<data_type> is the DBI C<TYPE_NAME> of the column -- the readable type name,
not the numeric C<DATA_TYPE> code. A DBD that reports no C<TYPE_NAME> gets
C<varchar> guessed for that column, with a warning naming it: the guess is
invisible in the generated class once it is written.

C<is_nullable> is the DBI C<NULLABLE> flag B<combined with> primary-key
membership from L</table_pk_info>: a key column is C<< is_nullable => 0 >>
however the DBD reports it. C<NULLABLE> answers only whether the column
carries a C<NOT NULL> attribute, and that is not the same question -- SQLite
keeps the primary-key constraint separate from the attribute, so DBD::SQLite
reports C<NULLABLE = 1> for C<id INTEGER PRIMARY KEY>.

A C<NULLABLE> of C<2> (DBI's "unknown"), or no C<NULLABLE> at all, gives
C<< is_nullable => 1 >> with a warning naming the column. Of the two possible
guesses only C<0> can do damage: it makes the generated class refuse an
C<INSERT> the database would have accepted, while C<1> leaves the engine's own
constraint to reject it with a real error.

=head2 table_pk_info

    my \@pk_cols = @{ $intro->table_pk_info($key) };

Ordered list of primary key column names.

=head2 table_uniq_info

    my \@constraints = @{ $intro->table_uniq_info($key) };

List of C<[ $constraint_name, \@col_names ]> pairs.

=head2 table_fk_info

    my \@fks = @{ $intro->table_fk_info($key) };

Each FK is a hashref:

    {
      local_columns  => [qw/author_id/],
      remote_table   => 'authors',
      remote_schema  => 'public',   # may be undef
      remote_columns => [qw/id/],   # may be [] (use remote PK)
      attrs          => {},
    }

=head2 table_is_view

Returns true if C<$key> is a view rather than a base table.

=head2 view_definition

SQL text of the view definition, or C<undef>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
