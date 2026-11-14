package DBIO::Deploy::Base::TempDatabase;
# ABSTRACT: Deploy base for drivers that diff against a temporary database

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Deploy::Base';

use DBI;
use DBIO::Util ();


sub _create_temp_db { die ref(shift) . '::_create_temp_db not implemented' }


sub _drop_temp_db { die ref(shift) . '::_drop_temp_db not implemented' }


sub temp_db_prefix { $_[0]->{temp_db_prefix} // '_dbio_tmp_' }


sub _build_target_model {
  my ($self) = @_;

  # The connect info is read once before any temp database exists: one the
  # temp connection cannot be derived from stops the build here.
  $self->_temp_connect_info('probe');

  my $dbh = $self->_admin_dbh;

  my $temp_db = eval { $self->_create_temp_db($dbh) };
  my $create_err = $@;
  unless (defined $temp_db) {
    $self->_release_admin_dbh;
    die $create_err;
  }

  my $model = eval { $self->_deploy_and_introspect_temp($temp_db) };
  my $err   = $@;

  # Warned about and not raised (karr k316): the model is there, or $err is
  # what the caller has to hear. With a plain warn, as DBIO::Deploy::Base
  # does it -- no DBIO::Carp in a deploy class.
  eval { $self->_drop_temp_db($dbh, $temp_db); 1 } or do {
    my $drop_err = "$@";
    # a DBD may repeat the DSN or the password in its error: never the
    # password (karr k297). _temp_connect_info dies of a coderef DSN, and the
    # warning is not to fail of what it is masked with.
    my $info = eval { [ $self->_temp_connect_info($temp_db) ] };
    ($drop_err = DBIO::Util::mask_connect_secrets($drop_err, $info)) =~ s/\s+\z//;
    warn ref($self) . ": temporary database '$temp_db' could not be dropped and "
       . "is still on the server -- drop it by hand: $drop_err\n";
  };

  $self->_release_admin_dbh;

  die $err if $err;
  return $model;
}


sub _admin_dbh {
  my ($self) = @_;
  my $storage = $self->schema->storage;
  my $live = $self->_dbh;
  return $live
    unless ($storage->can('transaction_depth') && $storage->transaction_depth)
        || !$live->{AutoCommit};

  my ($dsn, $user, $pass) = @{ $storage->_dbi_connect_info };
  my $dbh = eval {
    DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    })
  } or die DBIO::Util::mask_connect_secrets(
    $@ || "Cannot connect to the database: $DBI::errstr", [ $dsn, $user, $pass ],
  );
  $self->{_admin_dbh} = $dbh;
  return $dbh;
}

# Closes the connection _admin_dbh opened, if it opened one. A failing
# disconnect changes nothing about the outcome of the build.
sub _release_admin_dbh {
  my ($self) = @_;
  my $own = delete $self->{_admin_dbh} or return;
  eval { $own->disconnect; 1 };
  return;
}


sub _deploy_and_introspect_temp {
  my ($self, $temp_db) = @_;

  my ($dsn, $user, $pass) = $self->_temp_connect_info($temp_db);
  # DBI dies quoting the DSN it was given: never the password (karr k297)
  my $temp_dbh = eval {
    DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    })
  } or die DBIO::Util::mask_connect_secrets(
    $@ || "Cannot connect to temp database: $DBI::errstr", [ $dsn, $user, $pass ],
  );

  my $err;
  eval { $self->_execute_ddl($temp_dbh, $self->_install_ddl); 1 } or $err = $@;

  my $model;
  unless ($err) {
    eval { $model = $self->_new_introspect($temp_dbh)->model };
    $err = $@ unless $model;
  }

  # a disconnect that fails is raised only when nothing else was: it does not
  # replace the error of the deploy (karr k316)
  eval { $temp_dbh->disconnect; 1 } or $err ||= $@;

  die $err if $err;
  return $model;
}


sub _temp_connect_info {
  my ($self, $temp_db) = @_;
  my ($dsn, $user, $pass) = @{ $self->schema->storage->_dbi_connect_info };

  if (ref $dsn eq 'CODE') {
    die ref($self) . ' does not support coderef DSN for temp database connections';
  }
  if (!defined $dsn || ref $dsn || $dsn eq '') {
    die ref($self) . ' cannot derive a temp database connection: '
      . 'the storage has no DSN (a plain, non-empty string) to derive it from';
  }

  return ($self->_temp_dsn($dsn, $temp_db), $user, $pass);
}


sub _temp_dsn {
  my ($self, $dsn, $temp_db) = @_;

  if ($dsn =~ /(?:database|dbname)=/i) {
    $dsn =~ s/(database|dbname)=[^;]+/$1=$temp_db/i;
  }
  else {
    $dsn .= ";dbname=$temp_db";
  }

  return $dsn;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Deploy::Base::TempDatabase - Deploy base for drivers that diff against a temporary database

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

A L<DBIO::Deploy::Base> specialization for drivers whose C<diff> builds the
target model by deploying the desired schema into a freshly created temporary
I<database> and introspecting it -- PostgreSQL and MySQL. (Drivers that use an
in-memory database, such as DuckDB and SQLite, do not need this: they override
L<DBIO::Deploy::Base/_build_target_model> with a C<:memory:> connection.)

It provides the shared temp-database orchestration:

=over 4

=item * L</_build_target_model> -- create a temp db, deploy + introspect into
it, then B<always> try to drop it (even if the deploy or introspection dies),
and re-raise any error of the deploy afterwards. A drop that fails is warned
about, naming the database that is still on the server.

=item * L</_deploy_and_introspect_temp> -- connect to the temp db, run the
install DDL, introspect, disconnect.

=item * L</_temp_connect_info> -- derive the temp-db connection info from the
live storage's connect info by rewriting the database name in the DSN.

=back

A subclass supplies only the genuinely engine-specific seam: L</_create_temp_db>
and L</_drop_temp_db> (the C<CREATE DATABASE> / C<DROP DATABASE> dialect, and
any transaction handling), plus the three class-name hooks from
L<DBIO::Deploy::Base>.

=head1 METHODS

=head2 _create_temp_db

    my $name = $self->_create_temp_db($dbh);

Create a uniquely-named temporary database and return its name. Abstract --
the C<CREATE DATABASE> statement and quoting/transaction handling are
engine-specific.

The C<$dbh> it is handed has C<AutoCommit> on and holds no transaction of the
caller's. The method ends no transaction itself -- no C<COMMIT>, no
C<< local $dbh->{AutoCommit} = 1 >>, which commits the open one inside L<DBI>
-- and leaves the handle's C<AutoCommit> as it found it.

=head2 _drop_temp_db

    $self->_drop_temp_db($dbh, $name);

Drop the temporary database named C<$name>. Abstract.

The C<$dbh> is the one L</_create_temp_db> was handed: C<AutoCommit> on, no
transaction of the caller's. The method ends no transaction itself and leaves
the handle's C<AutoCommit> as it found it.

=head2 temp_db_prefix

Prefix for generated temp-database names. Defaults to C<_dbio_tmp_>. A
subclass's L</_create_temp_db> typically builds the full name as
C<< prefix . $$ . '_' . time() >>.

=head2 _build_target_model

Reads the temp connection info once (L</_temp_connect_info>) before anything
is created: a storage it cannot be derived from dies here, with no temp
database made. Then creates a temp database, deploys + introspects the desired schema into it via
L</_deploy_and_introspect_temp>, and drops the temp database. The drop runs
B<unconditionally> (wrapped in its own C<eval>), so a failed deploy or
introspection does not by itself leak a temp database; the original error is
then re-raised.

A drop that fails does not change the outcome: the model is returned, or the
error of the deploy re-raised, as if it had worked. But the database is then
still on the server, so the failure is warned about, by the name of the
database and with the error of the drop -- passwords in it shown as C<***> --
for it to be dropped by hand. Every database left behind gets its own
warning.

=head2 _admin_dbh

The handle C<CREATE DATABASE> and C<DROP DATABASE> run on, handed to
L</_create_temp_db> and L</_drop_temp_db>. It has C<AutoCommit> on, and a
driver ends no transaction on it, so the transaction of the caller stays as it
is. Whenever the storage holds a transaction, or the live handle has
C<AutoCommit> off -- also one the storage does not know of, from C<begin_work>
on the raw handle or C<< AutoCommit => 0 >> in the connect info -- the
statements run on a connection of their own to the live database, C<AutoCommit>
on, closed again when the build is done. Otherwise the live handle is used.

=head2 _deploy_and_introspect_temp

    my $model = $self->_deploy_and_introspect_temp($temp_db);

Connects to C<$temp_db> (via L</_temp_connect_info>), runs the install DDL,
introspects the result, disconnects, and returns the model. Errors during
deploy or introspection are re-raised I<after> the connection is closed, and
are what is raised when closing it fails as well; an error of the disconnect
is raised when it is the only one. A connection that cannot be opened dies
with L<DBI>'s error, the password in it shown as C<***>.

=head2 _temp_connect_info

    my ($dsn, $user, $pass) = $self->_temp_connect_info($temp_db);

Derives connection info for the temp database from the live storage's
normalised C<_dbi_connect_info> (C<[ $dsn, $user, $password, \%attrs ]>),
rewriting the C<dbname=> / C<database=> component of the DSN to C<$temp_db>
(appending it when absent). The storage is read as it is at the moment of the
call, with or without an AccessBroker (then the broker's current answer), and
nothing of it is kept. The DSN has to be a plain, non-empty string: a coderef
DSN (also a broker answer that is a C<dbh_maker>), a missing, an empty or a
non-scalar DSN dies.

=head2 _temp_dsn

    my $temp_dsn = $self->_temp_dsn($dsn, $temp_db);

Given the live storage's C<$dsn> and the temp-database name C<$temp_db>, return
the DSN string used to connect to the temp database. The default rewrites the
C<database=> / C<dbname=> component of C<$dsn> to C<$temp_db> (appending
C<;dbname=$temp_db> when absent) -- the standard form for engines whose DSN
names the database with a C<dbname=> key (PostgreSQL, MySQL).

This is the single overridable seam for the temp-db DSN I<form>: a driver whose
DSN shape differs (e.g. Firebird's C<dbi:Firebird:localhost:$db>) overrides only
this method and inherits the rest of L</_temp_connect_info> (the connect-info
shape handling, user/password extraction, coderef-DSN guard).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
