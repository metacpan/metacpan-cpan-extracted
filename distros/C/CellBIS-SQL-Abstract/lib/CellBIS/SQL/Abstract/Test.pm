package CellBIS::SQL::Abstract::Test;
$CellBIS::SQL::Abstract::Test::VERSION = '1.3';
use Mojo::Base -base;

use Carp 'croak';
use Mojo::Loader 'load_class';
use Mojo::Util qw(dumper);
use Mojo::Home;
use CellBIS::SQL::Abstract;
use CellBIS::SQL::Abstract::Test::Table;

has 'dsn';
has 'via';
has 'backend';
has 'table';

# internal purpose
has 'abstract';
has 'dir';
has home => sub {
  state $home = Mojo::Home->new;
};
has table_info => sub {
  state $table = CellBIS::SQL::Abstract::Test::Table->new;
};

sub create_table {
  my $self = shift;

  my $result = {result => 0, code => 400};
  my $dbtype = $self->via;
  my $table  = $self->table;

  my @table_info = $self->table_info->$table->$dbtype;
  my $q          = $self->abstract->create_table(@table_info);
  if (my $dbh = $self->backend->db->query($q)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub create_table_with_fk {
  my $self = shift;

  my ($result, $dbtype, $table_users, $table_roles, @table_info, $table, $q);
  $result      = {result => 0, code => 400};
  $dbtype      = $self->via;
  $table       = $self->table;
  $table_users = $self->table_info->users;
  $table_roles = $self->table_info->roles;

  # table construction
  @table_info = $self->table_info->$table->$dbtype;
  push @table_info,
    {
    fk => {
      name         => 'users_roles_id',
      col_name     => $table_users->id_roles,
      table_target => $table_roles->table_name,
      col_target   => $table_roles->id,
      attr         => {onupdate => 'cascade', ondelete => 'cascade'}
    }
    };
  $q = $self->abstract->create_table(@table_info);
  if (my $dbh = $self->backend->db->query($q)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub check_table {
  my $self = shift;

  my ($result, $dbtype, $table_info, $table, @pre_q, $q);
  $result     = {result => 0, code => 400};
  $dbtype     = $self->via;
  $table      = $self->table;
  $table_info = $self->table_info->$table;

  @pre_q = (
    'sqlite_master',
    ['name'],
    {
      where => 'type=\'table\' AND tbl_name=\''
        . $table_info->table_name . '\''
    }
  ) if $dbtype eq 'sqlite';
  @pre_q = (
    'information_schema.tables', ['table_name'],
    {where => 'table_name=\'' . $table_info->table_name . '\''}
  ) if $dbtype eq 'mariadb';
  @pre_q = (
    'information_schema.tables',
    ['table_name'],
    {
      where =>
        'table_type=\'BASE TABLE\' AND table_schema=\'public\' AND table_name=\''
        . $table_info->table_name . '\''
    }
  ) if $dbtype eq 'pg';

  $q = $self->abstract->select(@pre_q);
  if (my $dbh = $self->backend->db->query($q)) {
    $result->{result} = $dbh->hash;
    $result->{code}   = 200;
  }
  return $result;
}

sub empty_table {
  my $self = shift;

  my ($result, $dbtype, $table, $table_info);
  $dbtype     = $self->via;
  $table      = $self->table;
  $table_info = $self->table_info->$table;
  $result     = {result => 0, code => 500};

  if (my $dbh
    = $self->backend->db->query('DELETE FROM ' . $table_info->table_name))
  {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub drop_table {
  my $self = shift;

  my ($result, $dbtype, $table, $table_info);
  $dbtype     = $self->via;
  $table      = $self->table;
  $table_info = $self->table_info->$table;
  $result     = {result => 0, code => 500};

  if (
    my $dbh = $self->backend->db->query(
      'DROP TABLE IF EXISTS ' . $table_info->table_name
    )
    )
  {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub create {
  my $self = shift;

  my ($result, $dbtype, $table, $table_info);
  $dbtype     = $self->via;
  $table      = $self->table;
  $table_info = $self->table_info->$table;

  # return if table is not exist.
  $result = {result => 0, code => 500};
  return $result unless $self->check_table->{result};

  $result = {result => 0, code => 400};
  my $q = $self->abstract->insert();
  if (my $dbh = $self->backend->db->query($q)) {
    $result->{result} = $dbh->rows;
    $result->{code}   = 200;
  }
  return $result;
}

sub change_dbms {
  my ($self, $dbms) = @_;

  $dbms //= 'sqlite';
  $self->{via} = $dbms;
  $self->abstract(CellBIS::SQL::Abstract->new(db_type => $self->via));
  my $backend = 'Mojo::mysql' if $self->via eq 'mariadb';
  $backend = 'Mojo::Pg'     if $self->via eq 'pg';
  $backend = 'Mojo::SQLite' if $self->via eq 'sqlite';

  # dsn attribute alert
  croak 'dsn attribute must be defined'
    if ($self->via ne 'sqlite' && $self->dsn =~ /^sqlite\:/);

  # Only for SQLite
  if ($self->via eq 'sqlite') {
    $self->dir($self->home->child(qw(t db)));
    $self->dsn('sqlite:' . $self->dir . '/csa_test.db');
  }

  my $load = load_class $backend;
  croak ref $load ? $load : qq{Backend "$backend" missing} if $load;
  $self->backend($backend->new($self->dsn));

  return $self;
}

sub new {
  my $self = shift->SUPER::new(@_);

  my ($backend);
  $self->{via} //= 'sqlite';

  $self->abstract(CellBIS::SQL::Abstract->new(db_type => $self->via));
  $backend = 'Mojo::mysql'  if $self->via eq 'mariadb';
  $backend = 'Mojo::Pg'     if $self->via eq 'pg';
  $backend = 'Mojo::SQLite' if $self->via eq 'sqlite';

  # Only for SQLite
  if ($self->via eq 'sqlite') {
    $self->dir($self->home->child(qw(t db)));
    $self->dsn('sqlite:' . $self->dir . '/csa_test.db');
  }

  # Load Class for backend database type
  my $load = load_class $backend;
  croak ref $load ? $load : qq{Backend "$backend" missing} if $load;
  $self->backend($backend->new($self->dsn));

  return $self;
}
1;

=encoding utf8

=head1 NAME

CellBIS::SQL::Abstract::Test - A part of Unit Testing

=head1 SYNOPSIS

  use CellBIS::SQL::Abstract::Test;
  
  # Initialization for SQLite
  my $test = CellBIS::SQL::Abstract::Test->new(table => 'users');
  unless (-d $test->dir) { mkdir $test->dir }
  
  $backend = $test->backend;
  $db      = $backend->db;
  ok $db->ping, 'connected';
  
  # Initialization for MariaDB
  my $test = CellBIS::SQL::Abstract::Test->new(
    table => 'users',
    via   => 'mariadb',
    dsn   => 'mariadb://myuser:mypass@localhost:3306/mydbtest'
  );
  $backend = $test->backend;
  $db      = $backend->db;
  ok $db->ping, 'connected';
  
  # Initialization for PostgreSQL
  my $test = CellBIS::SQL::Abstract::Test->new(
    table => 'users',
    via   => 'pg',
    dsn   => 'posgresql://myuser:mypass@localhost:5432/mydbtest'
  );
  $backend = $test->backend;
  $db      = $backend->db;
  ok $db->ping, 'connected';

=head1 DESCRIPTION

This module is only a test instrument in SQLite, Mariadb, and PostgreSQL

=head1 ATTRIBUTES

L<CellBIS::SQL::Abstract::Test> implements the following attributes.

=head2 table

  my $test = CellBIS::SQL::Abstract::Test->new(
    ...
    table => 'users',
    ...
  );
  
  $test->table('users'); # to defined table
  $test->table;          # to use get table

Information of table form L<CellBIS::SQL::Abstract::Test::Table>

=head2 via and dsn

  # initialization for mariadb
  my $test = CellBIS::SQL::Abstract::Test->new(
    ...
    via => 'mariadb',
    dsn => 'mariadb://myuser:mypass@localhost:3306/mydbtest',
    ...
  );
  
  # initialization for postgresql
  my $test = CellBIS::SQL::Abstract::Test->new(
    ...
    via => 'pg',
    dsn => 'posgresql://myuser:mypass@localhost:3306/mydbtest',
    ...
  );
  
  # switch to mariadb
  $test->dsn('mariadb://myuser:mypass@localhost:3306/mydbtest');
  
  # switch to postgresql
  $test->dsn('posgresql://myuser:mypass@localhost:5432/mydbtest');
  
C<dsn> attribute must be defined together with C<via> attribute when
initializing mariadb or postgresql. However, when initializing using
sqlite, you don't need to use the C<via> and C<dsn> (Data Source Name)
attributes.

=head2 backend

  $test->backend;
  $test->backend(Mojo::SQLite->new);
  $test->backend(Mojo::mysq->new);
  $test->backend(Mojo::Pg->new);

C<backend> attribute only for initializing L<Mojo::SQLite>, L<Mojo::mysql>,
and L<Mojo::Pg>.

=head1 METHODS

L<CellBIS::SQL::Abstract::Test> implements the following new ones

=head2 change_dbms

This method for change dbms from one to the other. For example from
sqlite to mariadb or from mariadb to sqlite and vice versa.

  # switch to mariadb
  $test->dsn('mariadb://myuser:mypass@localhost:3306/mydbtest');
  $test->change_dbms('mariadb');
  
  # switch to postgresql
  $test->dsn('postgresql://myuser:mypass@localhost:5432/mydbtest');
  $test->change_dbms('pg');
  
  # switch back to sqlite
  $test->change_dbms('sqlite');
  unless (-d $test->dir) { mkdir $test->dir }

=head2 methods for tables query

The method here is to query tables, such as check, create, empty, and drop tables.

  $test->check_table;
  $test->create_table;
  $test->create_table_with_fk;
  $test->empty_table;
  $test->drop_table;
  
  # if use key hashref 'result'
  $test->check_table->{result};
  $test->create_table->{result};
  $test->create_table_with_fk->{result};
  $test->empty_table->{result};
  $test->drop_table->{result};
  
  # if use key hashref 'code'
  $test->check_table->{code};
  $test->create_table->{code};
  $test->create_table_with_fk->{code};
  $test->empty_table->{code};
  $test->drop_table->{code};

The output of this method is a hashref and contains key C<result> and C<code>.

=head1 AUTHOR

Achmad Yusri Afandi, C<yusrideb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Achmad Yusri Afandi

This program is free software, you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut
