package CellBIS::SQL::Abstract::Test::Table;
$CellBIS::SQL::Abstract::Test::Table::VERSION = '1.4';
use Mojo::Base -base;

has 'users';
has 'roles';

sub new {
  my $self = shift->SUPER::new(@_);

  my $table_users = __PACKAGE__ . '::_users';
  my $table_roles = __PACKAGE__ . '::_roles';

  $self->{users} = $table_users->new;
  $self->{roles} = $table_roles->new;

  return $self;
}

package CellBIS::SQL::Abstract::Test::Table::_users;
$CellBIS::SQL::Abstract::Test::Table::_users::VERSION = '1.4';
use Mojo::Base -base;

# Table fields
has table_name => 'users';
has id         => 'id_users';
has id_roles   => 'roles_id';
has firstname  => 'firstname';
has lastname   => 'lastname';
has fullname   => 'fullname';
has username   => 'username';
has password   => 'password';
has create     => 'date_create';
has update     => 'date_update';
has status     => 'status';

sub sqlite {
  my $self = shift;

  return (
    $self->table_name,
    [
      $self->id,       $self->id_roles, $self->firstname, $self->lastname,
      $self->fullname, $self->username, $self->password,  $self->create,
      $self->update,   $self->status
    ],
    {
      $self->id =>
        {type => {name => 'integer'}, is_primarykey => 1, is_autoincre => 1},
      $self->id_roles  => {type => {name => 'integer'}, is_null => 0},
      $self->firstname => {type => {name => 'varchar', size => 50}},
      $self->lastname  => {type => {name => 'varchar', size => 50}},
      $self->fullname  => {type => {name => 'varchar', size => 100}},
      $self->username  => {type => {name => 'varchar', size => 60}},
      $self->password  => {type => {name => 'text'}},
      $self->create    => {type => {name => 'datetime'}},
      $self->update    => {type => {name => 'datetime'}},
      $self->status    => {type => {name => 'int', size => 1}}
    }
  );
}

sub mariadb {
  my $self = shift;

  return (
    $self->table_name,
    [
      $self->id,       $self->id_roles, $self->firstname, $self->lastname,
      $self->fullname, $self->username, $self->password,  $self->create,
      $self->update,   $self->status
    ],
    {
      $self->id =>
        {type => {name => 'int'}, is_primarykey => 1, is_autoincre => 1},
      $self->id_roles  => {type => {name => 'int'}, is_null => 0},
      $self->firstname => {type => {name => 'varchar', size => 50}},
      $self->lastname  => {type => {name => 'varchar', size => 50}},
      $self->fullname  => {type => {name => 'varchar', size => 100}},
      $self->username  => {type => {name => 'varchar', size => 60}},
      $self->password  => {type => {name => 'text'}},
      $self->create    => {type => {name => 'datetime'}},
      $self->update    => {type => {name => 'datetime'}},
      $self->status    => {type => {name => 'int', size => 1}}
    }
  );
}

sub pg {
  my $self = shift;
  return (
    $self->table_name,
    [
      $self->id,       $self->id_roles, $self->firstname, $self->lastname,
      $self->fullname, $self->username, $self->password,  $self->create,
      $self->update,   $self->status
    ],
    {
      $self->id        => {type => {name => 'serial'}, is_primarykey => 1},
      $self->id_roles  => {type => {name => 'int'}, is_null => 0},
      $self->firstname => {type => {name => 'varchar', size => 50}},
      $self->lastname  => {type => {name => 'varchar', size => 50}},
      $self->fullname  => {type => {name => 'varchar', size => 100}},
      $self->username  => {type => {name => 'varchar', size => 60}},
      $self->password  => {type => {name => 'text'}},
      $self->create    => {type => {name => 'timestamp'}},
      $self->update    => {type => {name => 'timestamp'}},
      $self->status    => {type => {name => 'int'}}
    }
  );
}

package CellBIS::SQL::Abstract::Test::Table::_roles;
$CellBIS::SQL::Abstract::Test::Table::_roles::VERSION = '1.4';
use Mojo::Base -base;

# Table fields
has table_name => 'roles';
has id         => 'id_roles';
has name       => 'name';
has config     => 'config';

sub sqlite {
  my $self = shift;

  return (
    $self->table_name,
    [$self->id, $self->name, $self->config],
    {
      $self->id =>
        {type => {name => 'integer'}, is_primarykey => 1, is_autoincre => 1},
      $self->name   => {type => {name => 'varchar', size => 50}},
      $self->config => {type => {name => 'text'}}
    }
  );
}

sub mariadb {
  my $self = shift;

  return (
    $self->table_name,
    [$self->id, $self->name, $self->config],
    {
      $self->id =>
        {type => {name => 'int'}, is_primarykey => 1, is_autoincre => 1},
      $self->name   => {type => {name => 'varchar', size => 50}},
      $self->config => {type => {name => 'text'}}
    }
  );
}

sub pg {
  my $self = shift;

  return (
    $self->table_name,
    [$self->id, $self->name, $self->config],
    {
      $self->id     => {type => {name => 'serial'}, is_primarykey => 1},
      $self->name   => {type => {name => 'varchar', size => 50}},
      $self->config => {type => {name => 'text'}}
    }
  );
}

1;

=encoding utf8

=head1 NAME

CellBIS::SQL::Abstract::Test::Table - A part of Unit Testing
with contain information of tables

=head1 SYNOPSIS

  use CellBIS::SQL::Abstract::Test::Table;
  
  my $tables = CellBIS::SQL::Abstract::Test::Table->new;
  my $users  = $tables->users;
  my $roles  = $tables->roles;
  
  # get table field - users;
  $users->id;
  $users->id_roles;
  $users->firstname;
  $users->lastname;
  $users->fullname;
  $users->username;
  $users->password;
  $users->create;
  $users->update;
  $users->status;
  
  # get table field - roles;
  $roles->id;
  $roles->name;
  $roles->config;
  
  # get table query for users
  my $users_sqlite  = $users->sqlite;
  my $users_mariadb = $users->mariadb;
  my $users_pg      = $users->pg;
  
  # get table query for roles
  my $roles_sqlite  = $roles->sqlite;
  my $roles_mariadb = $roles->mariadb;
  my $roles_pg      = $roles->pg;

=head1 DESCRIPTION

This module is only for testing which contains 2 sample tables,
namely C<users> and C<roles>.

=head1 ATTRIBUTES AND METHODS

L<CellBIS::SQL::Abstract::Test::Table> implements two attributes,
namely C<users> and C<roles>.
Each attributes can call C<table field> attributes and method
for table query (C<sqlite, mariadb, pg>).

=head1 AUTHOR

Achmad Yusri Afandi, C<yusrideb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Achmad Yusri Afandi

This program is free software, you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut
