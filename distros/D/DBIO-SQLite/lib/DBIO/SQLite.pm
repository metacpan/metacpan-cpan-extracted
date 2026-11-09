package DBIO::SQLite;
# ABSTRACT: SQLite-specific schema management for DBIO
our $VERSION = '0.900004';
use strict;
use warnings;

use base 'DBIO::Base';

use Carp ();
use DBIO::SQLite::Extension ();

__PACKAGE__->mk_classdata('_sqlite_extensions' => []);
__PACKAGE__->mk_classdata('_sqlite_extension_options' => {});


sub sqlite_extensions {
  my $class = shift;
  if (@_) {
    my (@names, %options);
    my @args = @_;
    while (@args) {
      my $name = shift @args;
      Carp::croak(sprintf 'sqlite_extensions(): an extension name is expected, got %s',
        ref $name ? 'a ' . ref($name) . ' reference' : defined $name ? "'$name'" : 'undef')
        if !defined $name || ref $name || !length $name;
      push @names, $name unless grep { $_ eq $name } @names;
      next unless @args && ref $args[0];

      my $opts = shift @args;
      Carp::croak("sqlite_extensions(): the options of extension '$name' are a hashref")
        unless ref $opts eq 'HASH';
      Carp::croak("sqlite_extensions(): extension '$name' has an empty options hashref; give 'library' or 'class'")
        unless %$opts;
      for my $key (sort keys %$opts) {
        Carp::croak(sprintf
          "sqlite_extensions(): extension '%s' has no option %s; the options are 'library' and 'class'",
          $name, $key)
          unless $key eq 'library' || $key eq 'class';
      }
      Carp::croak("sqlite_extensions(): extension '$name' needs a 'library', a plain non-empty string")
        if exists $opts->{library}
          && !(defined $opts->{library} && !ref $opts->{library} && length $opts->{library});
      Carp::croak("sqlite_extensions(): extension '$name' needs a 'class', a class name")
        if exists $opts->{class}
          && !(defined $opts->{class} && !ref $opts->{class}
               && $opts->{class} =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/);
      $options{$name} = { %{ $options{$name} || {} }, %$opts };
    }
    $class->_sqlite_extensions(\@names);
    $class->_sqlite_extension_options(\%options);
  }
  return @{ $class->_sqlite_extensions };
}


sub sqlite_extension_options {
  my $class = shift;
  my $own = $class->_sqlite_extension_options;
  return { map { $_ => { %{ $own->{$_} } } } keys %$own };
}


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::SQLite::Storage');
  $self->_register_extension_layers;
  return $self->next::method(@info);
}

# The storage layer (ADR 0032) of every declared extension whose class names
# one is registered with core's register_storage_layer. An extension chooses
# a layer, never the driver: the driver is the one this component pinned above.
sub _register_extension_layers {
  my ($self) = @_;
  my $list = DBIO::SQLite::Extension->resolve_list($self, check_driver => 0)
    or return;
  for my $entry ($list->entries) {
    my $layer = $entry->{class}->storage_layer;
    $self->register_storage_layer($layer) if defined $layer;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite - SQLite-specific schema management for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

=head2 Schema class

  package MyApp::Schema;
  use DBIO Schema => -sqlite;

The C<-sqlite> shortcut pins C<+DBIO::SQLite::Storage> as the storage type.
It is equivalent to the explicit component form:

  package MyApp::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');

=head2 Result classes

  package MyApp::Schema::Result::Artist;
  use DBIO;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artist_id');

  package MyApp::Schema::Result::CD;
  use DBIO;

  __PACKAGE__->table('cd');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    artist_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 200 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(artist => 'MyApp::Schema::Result::Artist', 'artist_id');

=head2 Connecting

  my $schema = MyApp::Schema->connect('dbi:SQLite:db/app.db');
  $schema->deploy;

  my $artist = $schema->resultset('Artist')->create({ name => 'Sonic Youth' });
  my @cds    = $artist->cds->all;

The classic C<use base> form is still supported:

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

=head1 DESCRIPTION

L<DBIO::SQLite> is the SQLite driver component for DBIO.

When this component is loaded into a schema class, C<connection()> sets
L<DBIO::Schema/storage_type> to C<+DBIO::SQLite::Storage>, which enables
SQLite-specific storage behavior automatically.

=head1 METHODS

=head2 sqlite_extensions

Get or set the SQLite extensions this schema has.

  __PACKAGE__->sqlite_extensions('fts5');
  __PACKAGE__->sqlite_extensions('rtree', vec0 => { library => '/opt/sqlite/vec0.so' });
  __PACKAGE__->sqlite_extensions(spellfix1 => { class => 'MyApp::DB::Extension::Spellfix' });

The declaration is the list (ADR 0066): an extension is not pulled in by
loading a component, and a schema that does not declare C<fts5> has no FTS5
rules. A name may be followed by a hashref with the keys C<library> and C<class>:

=over 4

=item C<library>

The library C<< $dbh->sqlite_load_extension >> loads into every new
connection, a plain non-empty string. SQLite adds the platform's suffix when
the file is not found as given. A library that cannot be loaded dies when the
connection is set up, naming the extension and the library; a DBD::SQLite
without load-extension support dies the same way. The entry point is the one
SQLite derives from the file name.

=item C<class>

The extension class (a L<DBIO::Extension>) of an extension outside the
family; it wins over the driver's table. Without it a name of the family
(C<fts5>, C<rtree>) gets its class from the fixed table of
L<DBIO::SQLite::Extension>, any other name the plain class, which has no rules
for the model.

=back

Any other key, an empty hashref, a hashref without a name before it, a
C<library> that is not a plain non-empty string and a C<class> that is not a
class name croak. The list in list context is the names only, in the order
they were declared; the options are L</sqlite_extension_options>. A new call
replaces the list.

=head2 sqlite_extension_options

  my $options = __PACKAGE__->sqlite_extension_options;   # { vec0 => { library => '/opt/sqlite/vec0.so' } }

The options L</sqlite_extensions> declared, a hashref extension name to its
options. Only the extensions that gave some are in it. A copy: changing it
declares nothing.

=head2 connection

Overrides L<DBIO::Schema/connection> to force C<+DBIO::SQLite::Storage> as
C<storage_type>.

It also registers, with L<DBIO::Schema/register_storage_layer>, the storage
layer (ADR 0032) that the class of a declared extension names in its
C<storage_layer>, ahead of the composition core makes in this method. The
classes of the list are loaded and checked for their interface version here,
since the layer is chosen before the storage exists; the assertion of their
driver waits for the first use of the connection. An extension chooses a
layer, never the driver. No class of the family names one.

=head1 EXTENSIONS

A SQLite extension lives in the process and not in the file: nothing in the
database records that a library was loaded, and every connection loads it
again. The extensions a schema has are therefore a list it declares
(L</sqlite_extensions>), and the driver runs it (ADR 0066 of DBIO core):

  __PACKAGE__->sqlite_extensions('fts5', 'rtree');
  __PACKAGE__->sqlite_extensions(vec0 => { library => '/opt/sqlite/vec0.so' });

The deploy and the diff keep the shadow tables of FTS5 and R*Tree out of the
model (L<DBIO::SQLite::Deploy/EXTENSIONS>); a C<library> is loaded into every
new connection (L<DBIO::SQLite::Storage/_activate_extensions>). A schema that
declares no extension is not affected in any way. The classes behind the names
are L<DBIO::SQLite::Extension>.

=head1 MIGRATION NOTES

SQLite storage and SQLMaker classes were split out of the historical
DBIx::Class monolithic distribution:

=over 4

=item *

Old: C<DBIx::Class::Storage::DBI::SQLite>

=item *

New: C<DBIO::SQLite::Storage>

=item *

Old: C<DBIx::Class::SQLMaker::SQLite>

=item *

New: C<DBIO::SQLite::SQLMaker>

=back

A schema declares the driver with this component or C<use DBIO 'Schema',
-sqlite>; core picks no storage class from the DSN (core ADR 0067).

=head1 TESTING

SQLite tests in this distribution use in-memory databases and do not require
database credentials.

Offline SQLMaker tests can use L<DBIO::SQLite::Test> or L<DBIO::Test> with:

  storage_type => 'DBIO::SQLite::Storage'

Shared tests can also exercise the replicated path with:

  replicated   => 1,
  storage_type => 'DBIO::SQLite::Storage'

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
