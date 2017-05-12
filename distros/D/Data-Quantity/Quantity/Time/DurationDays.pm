package Data::Quantity::Time::DurationDays;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

# undef = Data::Quantity::Time::DurationDays->scale();
sub scale {
  return 'Days';
}

sub type {
  return 'temporal', 'duration';
}

use vars qw( $default_readable_format );
$default_readable_format ||= 'D days';

# $value = Data::Quantity::Time::DurationDays->readable_value($number)
# $value = Data::Quantity::Time::DurationDays->readable_value($number, $style)
sub readable_value {
  my $class_or_item = shift;
  my $value = shift;
  $class_or_item->new($value)->readable(@_);
}

# $string = $quantity->readable( @_ );
sub readable {
  my $duration_q = shift;
  my $style = shift;
  $style ||= $default_readable_format;
  my $days = $duration_q->value or return;
  
  if ( $style eq 'Y yrs' ) {
    my $years = int( $days / 365 );
    return "$years yrs";
  } elsif ( $style eq 'D days' ) {
    return "$days days";
  } else {
    croak "Unkown duration readable format: '$style'";
  }
}

1;
