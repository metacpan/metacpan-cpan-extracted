package DBIO::Deploy::Base::TempDatabase;
# ABSTRACT: Deploy base for drivers that diff against a temporary database

use strict;
use warnings;

use base 'DBIO::Deploy::Base';

use DBI;


sub _create_temp_db { die ref(shift) . '::_create_temp_db not implemented' }


sub _drop_temp_db { die ref(shift) . '::_drop_temp_db not implemented' }


sub temp_db_prefix { $_[0]->{temp_db_prefix} // '_dbio_tmp_' }


sub _build_target_model {
  my ($self) = @_;
  my $dbh = $self->_dbh;

  my $temp_db = $self->_create_temp_db($dbh);

  my $model = eval { $self->_deploy_and_introspect_temp($temp_db) };
  my $err   = $@;

  eval { $self->_drop_temp_db($dbh, $temp_db) };

  die $err if $err;
  return $model;
}


sub _deploy_and_introspect_temp {
  my ($self, $temp_db) = @_;

  my ($dsn, $user, $pass) = $self->_temp_connect_info($temp_db);
  my $temp_dbh = DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  }) or die "Cannot connect to temp database: $DBI::errstr";

  my $err;
  eval { $self->_execute_ddl($temp_dbh, $self->_install_ddl); 1 } or $err = $@;

  my $model;
  unless ($err) {
    eval { $model = $self->_new_introspect($temp_dbh)->model };
    $err = $@ unless $model;
  }

  $temp_dbh->disconnect;

  die $err if $err;
  return $model;
}


sub _temp_connect_info {
  my ($self, $temp_db) = @_;
  my $storage = $self->schema->storage;
  my @info    = @{ $storage->connect_info };

  my ($dsn, $user, $pass);
  if (ref $info[0] eq 'HASH') {
    my $h = $info[0];
    $dsn  = $h->{dsn};
    $user = $h->{user};
    $pass = $h->{password} // $h->{pass};
  }
  else {
    ($dsn, $user, $pass) = @info;
  }

  if (ref $dsn eq 'CODE') {
    die ref($self) . ' does not support coderef DSN for temp database connections';
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

version 0.900002

=head1 DESCRIPTION

A L<DBIO::Deploy::Base> specialization for drivers whose C<diff> builds the
target model by deploying the desired schema into a freshly created temporary
I<database> and introspecting it -- PostgreSQL and MySQL. (Drivers that use an
in-memory database, such as DuckDB and SQLite, do not need this: they override
L<DBIO::Deploy::Base/_build_target_model> with a C<:memory:> connection.)

It provides the shared temp-database orchestration:

=over 4

=item * L</_build_target_model> -- create a temp db, deploy + introspect into
it, then B<always> drop it (even if the deploy or introspection dies), and
re-raise any error afterwards.

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

=head2 _drop_temp_db

    $self->_drop_temp_db($dbh, $name);

Drop the temporary database named C<$name>. Abstract.

=head2 temp_db_prefix

Prefix for generated temp-database names. Defaults to C<_dbio_tmp_>. A
subclass's L</_create_temp_db> typically builds the full name as
C<< prefix . $$ . '_' . time() >>.

=head2 _build_target_model

Creates a temp database, deploys + introspects the desired schema into it via
L</_deploy_and_introspect_temp>, and drops the temp database. The drop runs
B<unconditionally> (wrapped in its own C<eval>) so a failed deploy or
introspection never leaks a temp database; the original error is then
re-raised.

=head2 _deploy_and_introspect_temp

    my $model = $self->_deploy_and_introspect_temp($temp_db);

Connects to C<$temp_db> (via L</_temp_connect_info>), runs the install DDL,
introspects the result, disconnects, and returns the model. Errors during
deploy or introspection are re-raised I<after> the connection is closed.

=head2 _temp_connect_info

    my ($dsn, $user, $pass) = $self->_temp_connect_info($temp_db);

Derives connection info for the temp database from the live storage's
C<connect_info>, rewriting the C<dbname=> / C<database=> component of the DSN
to C<$temp_db> (appending it when absent). Handles both the array
(C<$dsn, $user, $pass>) and single-hashref (C<< { dsn, user, password } >>)
connect-info shapes. Dies on a coderef DSN.

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
