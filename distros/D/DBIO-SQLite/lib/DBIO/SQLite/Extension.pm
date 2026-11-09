package DBIO::SQLite::Extension;
# ABSTRACT: The extension class of a SQLite extension without rules, and the driver's table of the family's classes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Extension';

# The driver's fixed table of the extensions the family ships a class for
# (ADR 0066 section 1.2): the engine's name to [ class, distribution ]. The
# table maps names to existing classes, nothing is derived from a name. A
# declaration that names a class of its own wins over it.
our %FAMILY = (
  fts5  => [ 'DBIO::SQLite::Extension::FTS5',  'DBIO-SQLite' ],
  rtree => [ 'DBIO::SQLite::Extension::RTree', 'DBIO-SQLite' ],
);


sub extension_interface { 1 }


sub driver { 'DBIO::SQLite' }


sub activation {
  my ($class, $ctx) = @_;
  my $self    = $ctx->{self} || {};
  my $library = ($self->{options} || {})->{library};
  return undef unless defined $library;
  return { load => { $self->{name} => $library } };
}


sub family_class {
  my ($class, $name) = @_;
  my $entry = $FAMILY{$name // ''} or return;
  return @$entry;
}


sub resolve_list {
  my ($class, $schema, %opt) = @_;
  return undef unless $schema;

  my $options = _schema_decl($schema, 'sqlite_extension_options') // {};

  my @declaration;
  for my $name (_schema_decl($schema, 'sqlite_extensions')) {
    my $own = $options->{$name};
    push @declaration, $name, ($own && %$own ? { %$own } : ());
  }
  return undef unless @declaration;

  require DBIO::Extension::List;
  my $list = DBIO::Extension::List->new(
    declaration => \@declaration,
    class_table => sub { $class->family_class($_[0]) },
    plain_class => __PACKAGE__,
  );
  $list->check_driver('DBIO::SQLite') if $opt{check_driver} // 1;
  return $list;
}

# A schema class that does not load the DBIO::SQLite component declares none.
sub _schema_decl {
  my ($schema, $method) = @_;
  return $schema->can($method) ? $schema->$method : ();
}


sub driver_helpers {
  require DBIO::SQLite::Util;
  return {
    quote_ident => \&DBIO::SQLite::Util::quote_identifier,
    table       => sub { [ table => $_[0] ] },
    column      => sub { [ column => $_[0], $_[1] ] },
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Extension - The extension class of a SQLite extension without rules, and the driver's table of the family's classes

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # A schema declares the extensions its database has; nothing else is written.
  __PACKAGE__->sqlite_extensions('fts5', 'rtree');

  # a loadable library, loaded into every connection
  __PACKAGE__->sqlite_extensions(vec0 => { library => '/opt/sqlite/vec0.so' });

  # an extension outside the family names its class
  __PACKAGE__->sqlite_extensions(spellfix1 => { class => 'MyApp::DB::Extension::Spellfix' });

=head1 DESCRIPTION

The extension classes of L<DBIO::SQLite/sqlite_extensions> (ADR 0066 of DBIO
core). This class is the B<plain> one: it has no rules for the model, so an
extension declared with it is kept and nothing is done for it beyond the one
thing a SQLite extension needs, its activation. It derives from
L<DBIO::Extension>, whose defaults do nothing, and states only the interface
version and the driver it belongs to. Its C<name> is C<undef> on purpose: one
class serves every name the table and the declaration do not know, and the name
of the list's entry stands (L<DBIO::Extension/name>).

An extension of SQLite lives in the process, not in the file: nothing in the
database records that a library was loaded, and the library has to be loaded
again by every connection. So the one rule of the plain class is
L</activation>, and the extension's state is not read from a catalog but by a
probe of the extension's own (L<DBIO::SQLite::Extension::FTS5/inspect>). See
L<DBIO::SQLite::Deploy/EXTENSIONS> for what the deploy does with a list.

=head2 The table of the family

  name    class                             distribution
  fts5    DBIO::SQLite::Extension::FTS5     DBIO-SQLite
  rtree   DBIO::SQLite::Extension::RTree    DBIO-SQLite

Both are modules compiled into libsqlite, with shadow tables in the user's
schema, which the classes claim. B<SpatiaLite is not in the table.> Its
metadata tables (C<geometry_columns>, C<spatial_ref_sys>, ...) would be claims
the same way, and the library a C<library> option, but C<mod_spatialite> could
not be loaded on the host this was written on, so there is no class that was
measured against the real thing. It is a gap, not a decision: declare
C<< spatialite => { library => 'mod_spatialite' } >> and the connection loads
it, but no rule knows its tables, and the deploy sees them as model tables.

=head1 METHODS

=head2 extension_interface

The interface version of L<DBIO::Extension>, 1.

=head2 driver

C<DBIO::SQLite>, the assertion that is checked once the DSN has decided the
driver (L<DBIO::Extension::List/check_driver>).

=head2 activation

C<< { load => { $name => $library } } >> when the declaration gave a
C<library>, nothing otherwise. The library is what
C<< $dbh->sqlite_load_extension >> gets (L<DBIO::SQLite::Storage/_activate_extensions>);
SQLite adds the platform's suffix and derives the entry point from the file name
when it is not found as given.

=head2 family_class

  my ($class, $distribution) = DBIO::SQLite::Extension->family_class('fts5');

The table of the family: the class and the distribution that ships it for a
name the family has a class for, the empty list for any other name. This is
the C<class_table> L<DBIO::SQLite::Extension/resolve_list> hands to
L<DBIO::Extension::List>.

=head2 resolve_list

  my $list = DBIO::SQLite::Extension->resolve_list($schema);
  my $list = DBIO::SQLite::Extension->resolve_list($schema, check_driver => 0);

The one place that turns the declaration of a schema (class or instance;
L<DBIO::SQLite/sqlite_extensions>, C<sqlite_extension_options>) into a
L<DBIO::Extension::List>: the family table, the option C<class>, the plain
class. Classes are loaded and their interface version is checked. Returns
C<undef> for a schema that declares none.

Unless C<check_driver> is false the driver assertion of every class is checked
as well (L<DBIO::Extension::List/check_driver>); that is for a caller that runs
after the driver is resolved -- the deploy, a new connection. Only the
registration of the storage layers at C<connection> passes false: the layer is
chosen before the DSN has decided anything, and the assertion waits for the
first use.

=head2 driver_helpers

The helpers every extension gets as C<< $ctx->{driver} >>, see
L<DBIO::SQLite::Deploy/Addresses>: C<quote_ident> and the address
constructors C<table> and C<column>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
