### Change History
  # 1999-02-21 Created. -Simon

package Data::Quantity::Size::Inches;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Number '-isasubclass';

# undef = Data::Quantity::Size::Inches->scale();
sub scale {
  return 'Inches';
}

# ($f, $i) = $inch_q->get_feet_and_inches;
sub get_feet_and_inches {
  my $inch_q = shift;
  my $count = $inch_q->value;
  my @values = ( int($count / 12), ($count % 12) );
  return wantarray ? @values : \@values;
}

# $inch_q->set_feet_and_inches($f, $i);
sub set_feet_and_inches {
  my $inch_q = shift;
  my ($f, $i) = @_;
  $inch_q->value( ($f * 12) + $i );
}

# $string = $quantity->readable($style)
sub readable {
  my $inch_q = shift;
  my $style = shift || 'short';
  
  if ( $style eq 'short' ) {
    my ($f, $i) = $inch_q->get_feet_and_inches;
    return ( $f ? $f."'" : '' ) . ( $i ? $i.'"' : '' )
  } elsif ( $style eq 'long' ) {
    my ($f, $i) = $inch_q->get_feet_and_inches;
    return ( $f ? $f." feet" : '' ) . 
	   ( $f && $i ? ' and ' : '' ) . 
 	   ( $i ? $i.' inches' : '' )
  } else {
    carp "Unknown format $style";    
  }
}

1;
