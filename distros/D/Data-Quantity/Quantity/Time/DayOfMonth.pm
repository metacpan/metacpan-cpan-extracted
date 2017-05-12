### Change History
  # 1998-12-02 Created. -Simon

package Data::Quantity::Time::DayOfMonth;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

# undef = Data::Quantity::Time::DayOfMonth->scale();
sub scale {
  return 'DayOfMonth';
}

# $value = Data::Quantity::Time::DayOfMonth->readable_value($number)
sub readable_value {
  my $class_or_item = shift;
  my $value = shift;
  
  return $value;
}

# $padded = $quantity->zero_padded();
sub zero_padded {
  my $date = shift;
  $date->SUPER::zero_padded( scalar @_ ? @_ : 2 );
}

1;
