package DBIO::DuckDB;
our $VERSION = '0.900004';


# ABSTRACT: DuckDB-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO::Base';

use Carp ();
use DBIO::DuckDB::Extension ();

__PACKAGE__->mk_classdata('_duckdb_extensions'        => []);
__PACKAGE__->mk_classdata('_duckdb_extension_classes' => {});


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::DuckDB::Storage');
  $self->_register_extension_layers;
  return $self->next::method(@info);
}

# The classes are loaded and checked for their interface here, since the layer
# has to be chosen before the storage is built; their driver assertion waits
# for the first use of the connection.
sub _register_extension_layers {
  my ($self) = @_;
  my $list = DBIO::DuckDB::Extension->resolve_list($self, check_driver => 0)
    or return;
  for my $entry ($list->entries) {
    my $layer = $entry->{class}->storage_layer;
    $self->register_storage_layer($layer) if defined $layer;
  }
  return;
}


sub duckdb_extensions {
  my $class = shift;
  if (@_) {
    my (@names, %classes);
    my @args = @_;
    while (@args) {
      my $name = shift @args;
      Carp::croak(sprintf
        'duckdb_extensions(): an extension name is expected, got %s',
        defined $name ? (ref $name ? 'a ' . ref($name) . ' reference' : "'$name'") : 'undef')
        if !defined $name || ref $name || !length $name;
      push @names, $name;
      next unless @args && ref $args[0];
      my $opts = shift @args;
      Carp::croak("duckdb_extensions(): the options of extension '$name' are a hashref")
        unless ref $opts eq 'HASH';
      my @unknown = grep { $_ ne 'class' } sort keys %$opts;
      Carp::croak(sprintf
        "duckdb_extensions(): extension '%s' has no option %s; the only option is 'class'",
        $name, join(', ', map { "'$_'" } @unknown))
        if @unknown;
      Carp::croak("duckdb_extensions(): extension '$name' has an empty options hashref; give 'class'")
        unless keys %$opts;
      my $extension_class = $opts->{class};
      Carp::croak("duckdb_extensions(): extension '$name' needs a 'class', a class name")
        unless defined $extension_class && !ref $extension_class
          && $extension_class =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;
      $classes{$name} = $extension_class;
    }
    $class->_duckdb_extensions(\@names);
    $class->_duckdb_extension_classes(\%classes);
  }
  return @{ $class->_duckdb_extensions };
}


sub duckdb_extension_classes { return { %{ $_[0]->_duckdb_extension_classes } } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB - DuckDB-specific schema management for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DuckDB');

  my $schema = MyApp::Schema->connect('dbi:DuckDB:dbname=app.duckdb');

  # or, using the `-du` shortcut:
  package MyApp::Schema;
  use DBIO Schema => -du;

=head1 DESCRIPTION

L<DBIO::DuckDB> is the DuckDB driver component for DBIO. When loaded into
a schema class, C<connection()> sets L<DBIO::Schema/storage_type> to
C<+DBIO::DuckDB::Storage>, which enables DuckDB-specific storage behavior.

The driver is built on top of L<DBD::DuckDB> (which itself is a pure-FFI
DBI driver -- no XS compile, only C<libduckdb> at runtime). DuckDB is an
embedded, synchronous, columnar analytical database. This driver keeps
the DBI plumbing for all the boring ORM work (transactions, bind, cursor,
ResultSet) and exposes the interesting DuckDB-native features as direct
methods on the storage object:

=over 4

=item * L<DBIO::DuckDB::Storage/duckdb_appender> -- bulk insert via the
DuckDB Appender API

=item * L<DBIO::DuckDB::Storage/duckdb_arrow_fetch> -- a result read
through libduckdb's Arrow interface and returned as columns

=item * L<DBIO::DuckDB::Storage/duckdb_read_csv>,
L<DBIO::DuckDB::Storage/duckdb_read_parquet>,
L<DBIO::DuckDB::Storage/duckdb_read_json> -- table-function helpers

=back

Schema management (install/diff/upgrade) uses the native
test-deploy-and-compare strategy via L<DBIO::DuckDB::Deploy>.

=head1 METHODS

=head2 connection

Overrides L<DBIO/connection> to force C<+DBIO::DuckDB::Storage> as
C<storage_type>, and registers the storage layer (ADR 0032) of every declared
extension whose class names one. An extension chooses a layer, never the
driver: the driver is the one pinned here.

=head2 duckdb_extensions

    __PACKAGE__->duckdb_extensions('httpfs', spatial => { class => 'MyApp::DB::Extension::Spatial' });

Get or set the DuckDB extensions the database of this schema has (ADR 0066 of
DBIO core). The declaration is a list of extension names, each optionally
followed by a hash reference of options. The only option is C<class>: the
extension class (a L<DBIO::Extension>) of an extension that has rules of its
own; it wins over the plain class. Every other option, an empty hash
reference, a second one, one without a name before it and a C<class> that is
no class name croak.

A declared extension is C<INSTALL>ed and C<LOAD>ed on every new connection of
the schema (L<DBIO::DuckDB::Storage/_activate_extensions>), and an upgrade
builds its throwaway target database with the same activation
(L<DBIO::DuckDB::Deploy/_build_target_model>), so a type an extension adds is
known to the target model. A deploy never drops an extension. Without a
declaration nothing is loaded. In list context returns the declared names.

=head2 duckdb_extension_classes

    my $classes = __PACKAGE__->duckdb_extension_classes;   # { spatial => 'MyApp::DB::Extension::Spatial' }

The classes L</duckdb_extensions> declared, as a hash reference extension name
to class name. Only the extensions that named one are in it. A copy: changing
it changes nothing.

=head1 TESTING

Tests use in-memory DuckDB databases and do not require external
credentials. The tests under C<t/> are automated TAP tests
(C<prove -l t/>); C<DBIO_TEST_DUCKDB_DSN> can override the DSN.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
