package Data::Quantity::Abstract::Base;

require 5;
use strict;
use Carp;
use Exporter;

use vars qw( $VERSION );
$VERSION = 0.001;

# $quantity = Data::Quantity::Subclass->new( @_ );
sub new {
  my $class_or_item = shift;
  my $class = ref $class_or_item || $class_or_item;
  my $quantity = $class->new_instance;
  $quantity->init( @_ );
  return $quantity;
}

# $empty_q = Data::Quantity::Subclass->new_instance();
sub new_instance {
  croak "abstract";
}

# $quantity->init( @_ );
sub init {
  croak "abstract";
}

sub value {
  croak "abstract";
}

sub scale {
  croak "abstract";
}


sub import {
  my $class = shift;
  
  if ( scalar @_ == 1 and $_[0] eq '-isasubclass' ) {
    shift;
    my $target_class = ( caller )[0];
    no strict;
    push @{"$target_class\::ISA"}, $class;
  }
  
  $class->SUPER::import( @_ );
}


1;
