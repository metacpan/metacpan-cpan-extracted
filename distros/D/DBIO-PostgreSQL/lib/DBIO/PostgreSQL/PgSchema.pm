package DBIO::PostgreSQL::PgSchema;
# ABSTRACT: Base class for PostgreSQL schema namespaces

use strict;
use warnings;

my (%_CLASS_ENUM_DEFS, %_CLASS_TYPE_DEFS, %_CLASS_FUNCTION_DEFS);


sub new {
  my ($class, %args) = @_;
  $args{_enums}     //= {};
  $args{_types}     //= {};
  $args{_functions} //= {};
  bless \%args, $class;
}

sub pg_schema_name { $_[0]->{pg_schema_name} }

sub _pg_enum_defs     { $_CLASS_ENUM_DEFS{     ref $_[0] || $_[0] } // [] }
sub _pg_type_defs     { $_CLASS_TYPE_DEFS{     ref $_[0] || $_[0] } // [] }
sub _pg_function_defs { $_CLASS_FUNCTION_DEFS{ ref $_[0] || $_[0] } // [] }



sub pg_enum {
  my ($self, $name, $values) = @_;
  if (ref $self) {
    $self->{_enums}{$name} = $values if $values;
    return $self->{_enums}{$name};
  }
  # Class method usage for declarative API
  my $class = $self;
  $_CLASS_ENUM_DEFS{$class} //= [];
  push @{ $_CLASS_ENUM_DEFS{$class} }, [$name, $values];
}


sub pg_type {
  my ($self, $name, $fields) = @_;
  if (ref $self) {
    $self->{_types}{$name} = $fields if $fields;
    return $self->{_types}{$name};
  }
  my $class = $self;
  $_CLASS_TYPE_DEFS{$class} //= [];
  push @{ $_CLASS_TYPE_DEFS{$class} }, [$name, $fields];
}


sub pg_function {
  my ($self, $name, $sql) = @_;
  if (ref $self) {
    $self->{_functions}{$name} = $sql if $sql;
    return $self->{_functions}{$name};
  }
  my $class = $self;
  $_CLASS_FUNCTION_DEFS{$class} //= [];
  push @{ $_CLASS_FUNCTION_DEFS{$class} }, [$name, $sql];
}


sub pg_enums {
  my ($self) = @_;
  return { %{ $self->{_enums} } };
}


sub pg_types {
  my ($self) = @_;
  return { %{ $self->{_types} } };
}


sub pg_functions {
  my ($self) = @_;
  return { %{ $self->{_functions} } };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PgSchema - Base class for PostgreSQL schema namespaces

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::PostgreSQL::PgSchema> is the base class for the intermediate
PostgreSQL schema (namespace) layer in DBIO. Subclass it to declare the
enums, composite types, and functions that belong to a specific PostgreSQL
namespace.

    package MyApp::DB::PgSchema::Auth;
    use base 'DBIO::PostgreSQL::PgSchema';

    __PACKAGE__->pg_schema_name('auth');

    __PACKAGE__->pg_enum('role_type' => [qw( admin moderator user guest )]);

    __PACKAGE__->pg_type('address_type' => {
        street => 'text',
        city   => 'text',
        zip    => 'varchar(10)',
    });

    __PACKAGE__->pg_function('update_modified_at' => q{
        CREATE OR REPLACE FUNCTION auth.update_modified_at()
        RETURNS TRIGGER AS $$ BEGIN NEW.modified_at = NOW(); RETURN NEW; END;
        $$ LANGUAGE plpgsql
    });

The class-method forms of C<pg_enum>, C<pg_type>, and C<pg_function> record
definitions that L<DBIO::PostgreSQL::DDL> reads when generating install DDL.
The instance-method forms are used at runtime when a C<PgSchema> object is
instantiated.

=head1 ATTRIBUTES

=head2 pg_schema_name

The PostgreSQL schema name (e.g. C<auth>, C<public>, C<api>). Required.

=head1 METHODS

=head2 _pg_enum_defs

    my $defs = $class->_pg_enum_defs;

Returns the arrayref of C<[$name, $values]> pairs declared on this specific
class via L</pg_enum>. Does not inherit from parent classes.

=head2 _pg_type_defs

    my $defs = $class->_pg_type_defs;

Returns the arrayref of C<[$name, $fields]> pairs declared on this class
via L</pg_type>.

=head2 _pg_function_defs

    my $defs = $class->_pg_function_defs;

Returns the arrayref of C<[$name, $sql]> pairs declared on this class
via L</pg_function>.

=head2 pg_enum

    # Class method (declarative — records for DDL generation):
    __PACKAGE__->pg_enum('role_type' => [qw( admin moderator user guest )]);

    # Instance method (runtime access):
    my $values = $obj->pg_enum('role_type');

Declare or retrieve an enum type definition. The C<values> arrayref preserves
declaration order, which PostgreSQL requires. Class-method calls accumulate
definitions consumed by L<DBIO::PostgreSQL::DDL>.

=head2 pg_type

    # Class method:
    __PACKAGE__->pg_type('address_type' => {
        street  => 'text',
        city    => 'text',
        zip     => 'varchar(10)',
        country => 'varchar(2)',
    });

    # Instance method:
    my $fields = $obj->pg_type('address_type');

Declare or retrieve a composite type definition. The fields hashref maps
attribute names to PostgreSQL type strings.

=head2 pg_function

    # Class method:
    __PACKAGE__->pg_function('update_modified_at' => q{
        CREATE OR REPLACE FUNCTION auth.update_modified_at()
        RETURNS TRIGGER AS $$ ... $$ LANGUAGE plpgsql
    });

    # Instance method:
    my $sql = $obj->pg_function('update_modified_at');

Declare or retrieve a function definition. The SQL string is emitted verbatim
by L<DBIO::PostgreSQL::DDL> during C<install_ddl>.

=head2 pg_enums

    my $all = $obj->pg_enums;  # hashref of name => values

Returns a copy of all enum definitions held by this instance.

=head2 pg_types

    my $all = $obj->pg_types;  # hashref of name => fields

Returns a copy of all composite type definitions held by this instance.

=head2 pg_functions

    my $all = $obj->pg_functions;  # hashref of name => sql

Returns a copy of all function definitions held by this instance.

=seealso

=over 4

=item * L<DBIO::PostgreSQL> - schema component (Database layer)

=item * L<DBIO::PostgreSQL::Result> - Result component (Table layer)

=item * L<DBIO::PostgreSQL::DDL> - reads PgSchema definitions to generate DDL

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
