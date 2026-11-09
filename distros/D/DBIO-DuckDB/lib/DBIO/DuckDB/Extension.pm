package DBIO::DuckDB::Extension;
# ABSTRACT: The extension class of a DuckDB extension without rules

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Extension';

use DBIO::Extension::List ();


sub extension_interface { 1 }


sub driver { 'DBIO::DuckDB' }


sub activation {
  my ($class, $ctx) = @_;
  return { load => $ctx->{self}{name} };
}


sub family_class { return }


sub resolve_list {
  my ($class, $schema, %opt) = @_;
  return undef unless $schema && $schema->can('duckdb_extensions');

  my $classes = $schema->duckdb_extension_classes;

  my @declaration;
  for my $name ($schema->duckdb_extensions) {
    push @declaration, $name, (defined $classes->{$name} ? { class => $classes->{$name} } : ());
  }
  return undef unless @declaration;

  my $list = DBIO::Extension::List->new(
    declaration => \@declaration,
    class_table => sub { $class->family_class($_[0]) },
    plain_class => __PACKAGE__,
  );
  $list->check_driver('DBIO::DuckDB') if $opt{check_driver} // 1;
  return $list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Extension - The extension class of a DuckDB extension without rules

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # A schema declares the extensions its database has; nothing else is written.
  __PACKAGE__->duckdb_extensions('httpfs', 'spatial');

  # An extension with rules of its own names its class
  __PACKAGE__->duckdb_extensions(spatial => { class => 'MyApp::DB::Extension::Spatial' });

=head1 DESCRIPTION

The extension classes of L<DBIO::DuckDB/duckdb_extensions> (ADR 0066 of DBIO
core). This class is the B<plain> one: it has no rules, so a declared extension
is installed and loaded and nothing else is done for it (C<httpfs>, C<json>,
C<parquet>, ...). It derives from L<DBIO::Extension>, whose defaults do
nothing, and states the interface version, the driver it belongs to and the one
thing a DuckDB extension wants of a connection: it is C<LOAD>ed
(L</activation>). Its C<name> is C<undef> on purpose: one class serves every
name, and the name of the list's entry stands (L<DBIO::Extension/name>).

Unlike PostgreSQL the driver ships no class for any extension: the table of the
family (L</family_class>) is empty and every name gets this class unless the
declaration names another with the option C<class>.

=head1 METHODS

=head2 extension_interface

The interface version of L<DBIO::Extension>, 1.

=head2 driver

C<DBIO::DuckDB>, the assertion that is checked once the DSN has decided the
driver (L<DBIO::Extension::List/check_driver>).

=head2 activation

The extension is loaded on every new connection: C<< { load => $name } >>,
with the name of the entry (C<< $ctx->{self}{name} >>). The storage turns it
into C<INSTALL> and C<LOAD> (L<DBIO::DuckDB::Storage/_activate_extensions>).

=head2 family_class

The table of the family: the empty list for every name, DuckDB has no extension
the family ships a class for. The C<class_table> L<DBIO::DuckDB::Deploy/_extension_list>
hands to L<DBIO::Extension::List>.

=head2 resolve_list

  my $list = DBIO::DuckDB::Extension->resolve_list($schema);
  my $list = DBIO::DuckDB::Extension->resolve_list($schema, check_driver => 0);

The one place that turns the declaration of a schema (class or instance;
L<DBIO::DuckDB/duckdb_extensions>, C<duckdb_extension_classes>) into a
L<DBIO::Extension::List>: the option C<class>, else the plain class. Classes are
loaded and their interface version is checked. Returns C<undef> for a schema
that declares none, and for one that does not load the L<DBIO::DuckDB>
component.

Unless C<check_driver> is false the driver assertion of every class is checked
as well (L<DBIO::Extension::List/check_driver>); only the registration of the
storage layers at C<connection> passes false, since the layer is chosen before
the DSN has decided anything.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
