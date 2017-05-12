### Change History
  # 1999-03-03 Stub created. -Simon

package Data::Quantity::Time::Time;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

sub new {
  my $package = shift;
  bless [ @_ ], $package;
}

# $hour = $time_q->hour;
sub hour {
  my $time_q = shift;
  $time_q->[0];
}

# $hour = $time_q->minute;
sub minute {
  my $time_q = shift;
  $time_q->[1];
}

# $hour = $time_q->second;
sub second {
  my $time_q = shift;
  $time_q->[2];
}

use vars qw( $default_readable_format );
$default_readable_format ||= 'hh:mm:ss';

sub readable {
  my $time_q = shift;
  
  my $style = shift;
  $style ||= $default_readable_format;
  
  my ( $sec, $min, $hour ) = ( $time_q->[2], $time_q->[1], $time_q->[0] );
  my ( $ss, $mm, $hh ) = ( $sec, $min, $hour );
  foreach ( $ss, $mm, $hh ) { 
    $_ = ( '0' x ( 2 - length($_) ) ) . $_;
  }
  my $h = ( $hour % 12 ) || 12;
  my $ampm = ( $hour > 11 ) ? 'pm' : 'am';
  my $AMPM = uc($ampm);
  
  if ( $style eq 'hh:mm:ss' ) {
    return "$hh:$mm:$ss";
  } elsif ( $style eq 'h:mmPM' ) {
    return "$h:$mm$AMPM";
  } else {
    croak "Unkown timestamp readable format.";
  }

}

1;
