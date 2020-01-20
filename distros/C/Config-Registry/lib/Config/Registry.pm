package Config::Registry;
our $VERSION = '0.01';
use strictures 2;

use Carp qw( croak );
use Hash::Merge qw();
use MRO::Compat;

use Moo;
use namespace::clean;

around BUILDARGS => sub{
  my $orig = shift;
  my $class = shift;

  my $args = $class->$orig( @_ );
  $args = $class->merge( $class->document(), $args );
  $args = $class->render( $args );

  return $args;
};

sub BUILD {
  my ($self) = @_;

  my $class = ref $self;
  croak "$class must be published before an instance may be built"
    if !$class->_get_class_data('is_published');

  return;
}

my %DATA;

sub _set_class_data {
  my ($class, $key, $value) = @_;
  my $data = $DATA{$class} ||= {};
  $data->{$key} = $value;
  return;
}

sub _get_class_data {
  my ($class, $key) = @_;

  my $isas = mro::get_linear_isa( $class );

  foreach my $isa (@$isas) {
    my $data = $DATA{ $isa };
    next if !$data;
    next if !exists $data->{$key};
    return $data->{$key};
  }

  return undef;
}

my $MERGER;

sub merge {
  $MERGER ||= Hash::Merge->new( 'RIGHT_PRECEDENT' );
  shift;
  return $MERGER->merge( @_ );
}

sub render {
  shift;
  return shift;
}

my %REGISTRIES;

sub fetch {
  my ($class) = @_;
  return $REGISTRIES{ $class } ||= $class->new();
}

sub schema {
  my ($class, $extra) = @_;

  my $schema = $class->_get_class_data('schema') || {};
  return $schema if !$extra;

  croak "Cannot change the registry schema after publishing $class"
    if $class->_get_class_data('is_published');

  $schema = $class->merge( $schema, $extra );
  $class->_set_class_data( schema => $schema );

  return $schema;
}

sub document {
  my ($class, $extra) = @_;

  my $document = $class->_get_class_data('document') || {};
  return $document if !$extra;

  croak "Cannot change the registry document after publishing $class"
    if $class->_get_class_data('is_published');

  $document = $class->merge( $document, $extra );
  $class->_set_class_data( document => $document );

  return $document;
}

sub publish {
  my ($class) = @_;

  croak "$class, or an ancestor class of, has already been published"
    if $class->_get_class_data('is_published');

  my $schema = $class->_get_class_data('schema') || {};

  $schema = $class->render( $schema );

  foreach my $key (keys %$schema) {
    my $spec = $schema->{$key};
    $spec = { isa=>$spec } if !ref $spec;

    $spec = {
      is       => 'ro',
      required => 1,
      %$spec,
    };

    # This is what the has() function does in Moo.pm.
    Moo->_constructor_maker_for( $class )
      ->register_attribute_specs( $key, $spec );
    Moo->_accessor_maker_for( $class )
      ->generate_method( $class, $key, $spec );
    Moo->_maybe_reset_handlemoose( $class );
  }

  $class->_set_class_data( is_published => 1 );

  return;
}

1;
__END__

=encoding utf8

=head1 NAME

Config::Registry - Settings bundler.

=head1 SYNOPSIS

=head2 Create a Schema Class

  package Org::Style;
  use strictures 2;
  
  use Types::Standard qw( Str );
  
  use Moo;
  use namespace::clean;
  
  extends 'Config::Registry';
  
  __PACKAGE__->schema({
    border_color => Str,
  });
  
  1;

=head2 Create a Document Class

  package MyApp::Style;
  use strictures 2;
  
  use Moo;
  use namespace::clean;
  
  extends 'Org::Style';
  
  __PACKAGE__->document({
    border_color => '#333',
  });
  
  __PACKAGE__->publish();
  
  1;

=head2 Use a Document Class

  use MyApp::Style;
  
  my $style = MyApp::Style->fetch();
  
  print '<table style="border-color:' . $style->border_color() . '">';

=head1 SYNOPSIS

This module provides a framework for a pattern we've seen emerge in
ZipRecruiter code as we've been working to separate our monolithic
application into smaller and more manageable code bases.

The concept is pretty straightforward.  A registry consists of a
schema class and one or more document classes.  The schema is used to
validate the documents, and the documents are used to configure the
features of an application.

=head1 SCHEMAS

  __PACKAGE__->schema({
    border_color => Str,
  });

The schema is a hash ref of attribute name and L<Type::Tiny> pairs.
These pairs get turned into required L<Moo> attributes when
L</publish> is called.

Top-level schema keys may have a hash ref, rather than a type, as
their value.  This hash ref will be used directly to construct the
L<Moo> attribute.  The C<required> option defaults on, and the C<is>
option default to C<ro>.  You can of course override these in the
hash ref.

For example, the above code could be written as:

  __PACKAGE__->schema({
    border_color => { isa => Str },
  });

The attribute can be made optional by passing an options hash ref:

  __PACKAGE__->schema({
    border_color => { isa => Str, required => 0 },
  });

Non-top level keys can be made optional using L<Type::Standard>'s
C<Optional> type modifier:

  __PACKAGE__->schema({
    border_colors => Dict[
      top    => Optional[ Str ],
      right  => Optional[ Str ],
      bottom => Optional[ Str ],
      left   => Optional[ Str ],
    ],
  });

See L</Create a Schema Role> for a complete example.

=head1 DOCUMENTS

  __PACKAGE__->document({
    border_color => '#333',
  });

A document is a hash ref of attribute name value pairs.

A document is used as the default arguments when C<new> is called
on the registry class.

See L</Create a Document Class> for a complete example.

=head1 PACKAGE METHODS

=head2 schema

  __PACKAGE__->schema( \%schema );

Sets the schema hash ref.  If a schema hash ref has already been
set then L</merge> will be used to combine the passed in schema with
the existing schema.

See L</SCHEMAS> for more information about the schema hash ref
itself.

=head2 document

  __PACKAGE__->document( \%doc );

Sets the document hash ref.  If a document hash ref has already been
set then L</merge> will be used to combine the passed in document with
the existing document.

See L</DOCUMENTS> for more information about the document hash ref
itself.

=head2 publish

  __PACKAGE__->publish();

Turns the L</schema> hash ref into L<Moo> attributes and enables the
registry class to be instantiated.

=head2 merge

  my $new_schema = $class->merge( $schema, $extra_schema );

This utility method does a C<RIGHT_PRECEDENT> L<Hash::Merge> and is
made available for those jobs that require a bit more customization
when building the schema and/or documents.

=head2 render

  my $document = $class->render( $raw_document );

Like L</merge>, this method is made available as a spot for subclasses
to customize behavior.  The default render method just returns what is
passed to it.  As an example, this method could be customized to pass
the schema and document data structures through L<Data::Xslate>.

=head1 SUPPORT

Please submit bugs and feature requests to the
Config-Registry GitHub issue tracker:

L<https://github.com/bluefeet/Config-Registry/issues>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/> for
encouraging their employees to contribute back to the open source
ecosystem.  Without their dedication to quality software development
this distribution would not exist.

=head1 AUTHOR

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

