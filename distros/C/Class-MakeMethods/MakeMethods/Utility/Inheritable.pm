=head1 NAME

Class::MakeMethods::Utility::Inheritable - "Inheritable" data


=head1 SYNOPSIS

  package MyClass;
  sub new { ... }
  
  package MySubclass;
  @ISA = 'MyClass';
  ...
  my $obj = MyClass->new(...);
  my $subobj = MySubclass->new(...);
  
  use Class::MakeMethods::Utility::Inheritable qw(get_vvalue set_vvalue );
  
  my $dataset = {};
  set_vvalue($dataset, 'MyClass', 'Foobar');    # Set value for class
  get_vvalue($dataset, 'MyClass');              # Gets value "Foobar"
  
  get_vvalue($dataset, $obj);                   # Objects "inherit"
  set_vvalue($dataset, $obj, 'Foible');         # Until you override
  get_vvalue($dataset, $obj);                   # Now finds "Foible"
  
  get_vvalue($dataset, 'MySubclass');           # Subclass "inherits"
  get_vvalue($dataset, $subobj);                # As do its objects
  set_vvalue($dataset, 'MySubclass', 'Foozle'); # Until we override it
  get_vvalue($dataset, 'MySubclass');           # Now finds "Foozle"
  
  get_vvalue($dataset, $subobj);                # Change cascades down
  set_vvalue($dataset, $subobj, 'Foolish');     # Until we override again
  
  get_vvalue($dataset, 'MyClass');              # Superclass is unchanged

=head1 DESCRIPTION

This module provides several functions which allow you to store values in a hash corresponding to both objects and classes, and to retrieve those values by searching a object's inheritance tree until it finds a matching entry.

This functionality is used by Class::MakeMethods::Standard::Inheritable and Class::MakeMethods::Composite::Inheritable to construct methods that can both store class data and be overriden on a per-object level.

=cut

########################################################################

package Class::MakeMethods::Utility::Inheritable;

$VERSION = 1.000;

@EXPORT_OK = qw( get_vvalue set_vvalue find_vself );
sub import { require Exporter and goto &Exporter::import } # lazy Exporter

use strict;

########################################################################

=head1 REFERENCE

=head2 find_vself

  $vself = find_vself( $dataset, $instance );

Searches $instance's inheritance tree until it finds a matching entry in the dataset, and returns either the instance, the class that matched, or undef.

=cut

sub find_vself {
  my $dataset = shift;
  my $instance = shift;

  return $instance if ( exists $dataset->{$instance} );
  
  my $v_self;
  my @isa_search = ( ref($instance) || $instance );
  while ( scalar @isa_search ) {
    $v_self = shift @isa_search;
    return $v_self if ( exists $dataset->{$v_self} );
    no strict 'refs';
    unshift @isa_search, @{"$v_self\::ISA"};
  }
  return;
}

=head2 get_vvalue

  $value = get_vvalue( $dataset, $instance );

Searches $instance's inheritance tree until it finds a matching entry in the dataset, and returns that value

=cut

sub get_vvalue {
  my $dataset = shift;
  my $instance = shift;
  my $v_self = find_vself($dataset, $instance);
  # warn "Dataset: " . join( ', ', %$dataset );
  # warn "Retrieving $dataset -> $instance ($v_self): '$dataset->{$v_self}'";
  return $v_self ? $dataset->{$v_self} : ();
}

=head2 set_vvalue

  $value = set_vvalue( $dataset, $instance, $value );

Searches $instance's inheritance tree until it finds a matching entry in the dataset, and returns that value

=cut

sub set_vvalue {
  my $dataset = shift;
  my $instance = shift;
  my $value = shift;
  if ( defined $value ) {
    # warn "Setting $dataset -> $instance = $value";
    $dataset->{$instance} = $value;
  } else {
    # warn "Clearing $dataset -> $instance";
    delete $dataset->{$instance};
    undef;
  }
}

########################################################################

1;
