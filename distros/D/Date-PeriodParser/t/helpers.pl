use strict;
use warnings;

sub set_time {
    my ($timestamp) = @_;

    my ($year, $mon, $day, $hour, $min, $sec) = split /[-T:]/, $timestamp;
    $year -= 1900;
    $mon--;

    $Date::PeriodParser::TestTime =
      timelocal( $sec, $min, $hour, $day, $mon, $year );
}

sub iso {
    my ($time) = @_;
    return strftime( "%Y-%m-%dT%H:%M:%S", localtime($time) );
}

1;
