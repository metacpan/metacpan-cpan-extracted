package Data::Quantity::Time::DurationSeconds;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

# undef = Data::Quantity::Time::DurationSeconds->scale();
sub scale {
  return 'Seconds';
}

sub type {
  return 'temporal', 'duration';
}

use vars qw( $default_readable_format );
$default_readable_format ||= 'h:m:s';

# $value = Data::Quantity::Time::DurationSeconds->readable_value($number)
# $value = Data::Quantity::Time::DurationSeconds->readable_value($number, $style)
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
  my $seconds = $duration_q->value or return;
  
  if ( $style eq 's' ) {
    return $seconds;
  } elsif ( $style eq 'h:m:s' ) {
    my $minutes = int($seconds / 60) and $seconds %= 60;
    my $hours = int($minutes / 60) and $minutes %= 60;
    if( $hours ) {
      my $mm = $minutes;
      my $ss = $seconds;
      foreach ( $mm, $ss ) { 
	$_ = ( '0' x ( 2 - length($_) ) ) . $_;
      }
      return $hours . ':' . $mm . ':' . $ss;
    } else {
      my $ss = $seconds;
      foreach ( $ss ) { 
	$_ = ( '0' x ( 2 - length($_) ) ) . $_;
      }
      return ( $minutes || '0' ) . ':' . $ss;
    }
  } else {
    croak "Unkown duration readable format: '$style'";
  }
}

1;
