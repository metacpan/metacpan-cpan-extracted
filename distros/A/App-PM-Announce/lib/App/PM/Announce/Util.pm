package App::PM::Announce::Util;

use strict;
use warnings;

use Date::Manip;
use Scalar::Util qw/blessed/;

sub age {
    my $class = shift;
    my $dtime = shift;
    $dtime->set_time_zone("UTC") if blessed $dtime && ($dtime = $dtime->clone);
    my $now = DateTime->now;


    my $age_delta = DateCalc(ParseDate($dtime.""), ParseDate($now.""));
    my ($week, $day, $hour, $minute, $second) = split m/:/, scalar Delta_Format($age_delta, 2, "\%wv:\%dv:\%hv:\%mv:\%sv");
    my $age;
    if ($week) {
        $age = scalar Delta_Format($age_delta, 2, "\%wh weeks");
    }
    elsif ($day) {
        $age = scalar Delta_Format($age_delta, 2, "\%dh days");
    }
    elsif ($hour) {
        $age = scalar Delta_Format($age_delta, 2, "\%hh hours");
    }
    elsif ($minute) {
        $age = scalar Delta_Format($age_delta, 2, "\%mh minutes");
    }
    else {
        $age = scalar Delta_Format($age_delta, 2, "\%sh seconds");
    }

   $age =~ s/s$// if $age =~ m/^1 /;

   return $age;
}

1;
