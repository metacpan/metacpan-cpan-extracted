### Change History
  # 1999-12-05 Added simplistic two_digit_window.
  # 1999-08-13 Added zero_padded
  # 1998-12-02 Created. -Simon

package Data::Quantity::Time::Year;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

# undef = Data::Quantity::Time::Year->scale();
sub scale {
  return 'Year';
}

# $value = Data::Quantity::Time::Year->readable_value($number)
# $value = Data::Quantity::Time::Year->readable_value($number, $style)
sub readable_value {
  my $class_or_item = shift;
  my $value = shift;
    
  return $value;
}

# $padded = $quantity->zero_padded();
sub zero_padded {
  my $year_q = shift;
  $year_q->SUPER::zero_padded( scalar @_ ? @_ : 4 );
}

sub two_digit_window {
  my $year_q = shift;
  my $years = $year_q->value;
  
  if ( $years > 1939 and $years < 2040 ) {
    $years =~ s/\A\d\d//;
  }
  return $years;
}

# $flag = $quantity->is_leap_year;
sub is_leap_year {
  my $year_q = shift;
  
  require Time::DaysInMonth;
  return Time::DaysInMonth::is_leap( $year_q->value );
}

1;
