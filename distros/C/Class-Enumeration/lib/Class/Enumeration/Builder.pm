# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;
use feature 'state';

package Class::Enumeration::Builder;

$Class::Enumeration::Builder::VERSION = 'v1.2.0';

use subs qw( _create_enum_object _is_equal );

use Carp      qw( croak );
use Sub::Util qw( set_subname );

use Class::Enumeration ();

sub import {
  shift;

  # TODO: Some options are relevant when import() is called at compile time;
  # others if import() is called at runtime.
  # If ( caller( 1 ) )[ 3 ] matches .*::BEGIN import() is called at compile
  # time.
  my $options = ref $_[ 0 ] eq 'HASH' ? shift : {};

  # $class == enum class
  my $class = exists $options->{ class } ? delete $options->{ class } : caller;

  # Now start building the enum class
  {
    no strict 'refs'; ## no critic ( ProhibitNoStrict )
    push @{ "$class\::ISA" }, 'Class::Enumeration'
  }

  my @values;
  my $counter = exists $options->{ counter } ? delete $options->{ counter } : sub { state $i = 0; $i++ };
  my $prefix  = exists $options->{ prefix }  ? delete $options->{ prefix }  : '';
  # Check if custom attributes were provided
  if ( ref $_[ 1 ] eq 'HASH' ) {
    my ( $reference_name, $reference_attributes ) = @_[ 0 .. 1 ];
    # Build list (@values) of enum objects
    while ( my ( $name, $attributes ) = splice @_, 0, 2 ) {
      croak "'$reference_name' enum and '$name' enum have different custom attributes, stopped"
        unless _is_equal $reference_attributes, $attributes;
      push @values, _create_enum_object $class, $counter, $prefix, $name, $attributes
    }
    # Build getters for custom attributes
    for my $getter ( keys %$reference_attributes ) {
      no strict 'refs'; ## no critic ( ProhibitNoStrict )
      *{ "$class\::$getter" } = set_subname "$class\::$getter" => sub { my ( $self ) = @_; $self->{ $getter } }
    }
  } else {
    # Build list (@values) of enum objects
    foreach my $name ( @_ ) {
      push @values, _create_enum_object $class, $counter, $prefix, $name;
    }
  }

  {
    no strict 'refs'; ## no critic ( ProhibitNoStrict )
    # Inject list of enum objects
    *{ "$class\::values" } = sub {
      sort { $a->ordinal <=> $b->ordinal } @values
    };
    # Optionally build enum constants and set @EXPORT_OK and %EXPORT_TAGS
    if ( delete $options->{ export } ) {
      my @names;
      for my $self ( @values ) {
        push @names, my $name = $self->name;
        *{ "$class\::$name" } = sub () { $self }
      }
      *{ "$class\::EXPORT_OK" }   = \@names;
      *{ "$class\::EXPORT_TAGS" } = { all => \@names };
    }
    # Optionally build enum object predicate methods
    if ( delete $options->{ predicate } ) {
      for my $self ( @values ) {
        my $name = $self->name;
        *{ "$class\::is_$name" } = sub { $_[ 0 ] == $self }
      }
    }
  }

  croak "Unknown options '${ \( join( q/', '/, keys %$options ) ) }' detected, stopped"
    if %$options;

  $class
}

sub _create_enum_object ( $$$$;$ ) {
  my ( $class, $counter, $prefix, $name, $attributes ) = @_;

  # Put each enum object in its own (dedicated) child class of the parent
  # enum class
  my $child_class = "$class\::$name";
  {
    no strict 'refs'; ## no critic ( ProhibitNoStrict )
    push @{ "$child_class\::ISA" }, $class
  }

  $child_class->_new( $counter->(), $prefix . $name, $attributes )
}

# Compare 2 sets of hash keys
sub _is_equal ( $$ ) {
  my ( $reference_attributes, $attributes ) = @_;

  my @reference_attributes = keys %$reference_attributes;
  return unless @reference_attributes == keys %$attributes;
  for ( @reference_attributes ) {
    return unless exists $attributes->{ $_ }
  }
  1
}

1
