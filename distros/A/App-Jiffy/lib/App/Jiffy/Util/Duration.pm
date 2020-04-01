package App::Jiffy::Util::Duration;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw/round/;

sub round {
  my $duration = shift;
  my $minute_period = shift // 15;

  # Round seconds
  my $seconds = $duration->seconds;
  if ( $seconds >= 30 ) {
    $duration->add( minutes => 1 );
  }
  $duration->subtract( seconds => $seconds );

  # Round minutes
  my $minutes = $duration->minutes;
  if ( $minutes % $minute_period >= $minute_period / 2 ) {
    $duration->add( minutes => $minute_period - ( $minutes % $minute_period ) );
  } else {
    $duration->subtract( minutes => $minutes % $minute_period );
  }
}

1;
