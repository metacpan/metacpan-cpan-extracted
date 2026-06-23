package DBIO::PostgreSQL;
# ABSTRACT: PostgreSQL-specific schema management for DBIO
our $VERSION = '0.900000';

use strict;
use warnings;

use base 'DBIO::Base';

__PACKAGE__->mk_classdata('_pg_schema_classes' => {});
__PACKAGE__->mk_classdata('_pg_extensions' => []);
__PACKAGE__->mk_classdata('_pg_search_path' => ['public']);
__PACKAGE__->mk_classdata('_pg_settings' => {});


sub pg_schemas {
  my $class = shift;
  if (@_) {
    my @schemas = @_;
    $class->_pg_schema_classes({
      map { $_ => undef } @schemas
    });
  }
  return keys %{ $class->_pg_schema_classes };
}


sub pg_schema_class {
  my ($class, $name, $pg_schema_class) = @_;
  my $classes = { %{ $class->_pg_schema_classes } };
  if ($pg_schema_class) {
    $classes->{$name} = $pg_schema_class;
    $class->_pg_schema_classes($classes);
  }
  return $classes->{$name};
}


sub pg_extensions {
  my $class = shift;
  if (@_) {
    $class->_pg_extensions([@_]);
  }
  return @{ $class->_pg_extensions };
}


sub pg_search_path {
  my $class = shift;
  if (@_) {
    $class->_pg_search_path([@_]);
  }
  return @{ $class->_pg_search_path };
}


sub pg_settings {
  my $class = shift;
  if (@_) {
    $class->_pg_settings($_[0]);
  }
  return $class->_pg_settings;
}


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::PostgreSQL::Storage');
  return $self->next::method(@info);
}


sub pg_deploy {
  my ($self, %args) = @_;
  require DBIO::PostgreSQL::Deploy;
  return DBIO::PostgreSQL::Deploy->new(
    schema => $self,
    %args,
  );
}


sub pg_install_ddl {
  my ($self) = @_;
  require DBIO::PostgreSQL::DDL;
  return DBIO::PostgreSQL::DDL->install_ddl($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL - PostgreSQL-specific schema management for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

=head2 Schema class

  package MyApp::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('PostgreSQL');

  __PACKAGE__->pg_schemas(qw( public auth ));

Or use the C<-pg> shortcut, which pins
C<+DBIO::PostgreSQL::Storage> as the storage type directly:

  package MyApp::Schema;
  use DBIO Schema => -pg;

=head2 Result classes

  package MyApp::Schema::Result::Artist;
  use DBIO;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');

For result classes with PostgreSQL-native features, use C<-pg> to load
L<DBIO::PostgreSQL::Result>:

  package MyApp::Schema::Result::User;
  use DBIO -pg;

  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid', default_value => \'gen_random_uuid()' },
    name => { data_type => 'varchar', size => 100 },
    tags => { data_type => 'text[]' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_index('idx_users_name' => { columns => ['name'] });
  __PACKAGE__->pg_index('idx_users_tags' => { using => 'gin', columns => ['tags'] });

=head2 Connecting

  my $schema = MyApp::Schema->connect($dsn, $user, $pass);

The classic C<use base> form is still supported:

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');

=head1 DESCRIPTION

L<DBIO::PostgreSQL> is the PostgreSQL driver component for DBIO.

When this component is loaded into a schema class, C<connection()> sets
L<DBIO::Schema/storage_type> to C<+DBIO::PostgreSQL::Storage>, which enables
PostgreSQL-specific storage behavior automatically.

This distribution also provides PostgreSQL-native DDL/deploy helpers and
introspection/diff tooling.

=head1 METHODS

=head2 pg_schemas

Get or set the list of PostgreSQL schema names tracked by this schema class.

=head2 pg_schema_class

Get or set the class mapped to a specific PostgreSQL schema name.

=head2 pg_extensions

Get or set PostgreSQL extensions to include during deploy/DDL operations.

=head2 pg_search_path

Get or set the default PostgreSQL C<search_path> list.

=head2 pg_settings

Get or set additional PostgreSQL settings stored on the schema class.

=head2 connection

Overrides L<DBIO/connection> to force
C<+DBIO::PostgreSQL::Storage> as C<storage_type>.

=head2 pg_deploy

Returns a L<DBIO::PostgreSQL::Deploy> instance for the schema.

=head2 pg_install_ddl

Generates PostgreSQL-native DDL statements for the schema.

=head1 MIGRATION NOTES

The PostgreSQL storage class was split out of the historical DBIx::Class
monolithic distribution:

=over 4

=item *

Old: C<DBIx::Class::Storage::DBI::Pg>

=item *

New: C<DBIO::PostgreSQL::Storage>

=back

If C<DBIO-PostgreSQL> is installed, core L<DBIO::Storage::DBI> can autodetect
PostgreSQL DSNs and load the new storage class via the driver registry.

=head1 TESTING

Integration tests in this distribution use:

  DBIO_TEST_PG_DSN
  DBIO_TEST_PG_USER
  DBIO_TEST_PG_PASS

SQLMaker-focused tests can run offline via L<DBIO::Test> with:

  storage_type => 'DBIO::PostgreSQL::Storage'

Replicated-path tests can reuse the same harness with:

  replicated   => 1,
  storage_type => 'DBIO::PostgreSQL::Storage'

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
