### Change History
  # 1999-08-13 Added padding
  # 1999-02-21 Created. -Simon

package Data::Quantity::Number::Integer;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Number '-isasubclass';

# $previous_q = $quantity->previous;
# $next_q = $quantity->previous( $incr );
sub previous {
  my $quantity = shift;
  my $clone = $quantity->new_instance;
  my $incr = scalar(@_) ? shift : 1;
  $clone->value( $quantity->value - $incr );
  return $clone;
}

# $next_q = $quantity->next;
# $next_q = $quantity->next( $incr );
sub next {
  my $quantity = shift;
  my $clone = $quantity->new_instance;
  my $incr = scalar(@_) ? shift : 1;
  $clone->value( $quantity->value + $incr );
  return $clone;
}

# $padded = $quantity->zero_padded( $positions );
sub zero_padded {
  my $quantity = shift;
  my $value = $quantity->value;
  my $places = shift;
  return ( '0' x ( $places - length($value) ) ) . $value;
}

# $padded = $quantity->zero_padded_value( $value, $positions );
sub zero_padded_value {
  my $quantity = shift;
  my ($value, $places) = @_;
  return ( '0' x ( $places - length($value) ) ) . $value;
}

1;
