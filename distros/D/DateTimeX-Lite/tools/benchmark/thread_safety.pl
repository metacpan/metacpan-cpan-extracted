#!/usr/bin/perl -l

use strict;
use warnings;
use DateTime;
use DateTimeX::Lite;
use Env::C;
use POSIX "mktime";

sub convert_timezone_datetime {
    my ($y,$mo,$d,$h,$m,$s,$tz,$new_tz) = @_;

    my $dt = DateTime->new(year=>$y, month=>$mo, day=>$d, hour=>$h,
minute=>$m, second=>$s,time_zone=>$tz);
    $dt->set_time_zone($new_tz);

    return map $dt->$_, qw/year month day hour minute second/;
}

sub convert_timezone_datetime_lite {
    my ($y,$mo,$d,$h,$m,$s,$tz,$new_tz) = @_;

    my $dt = DateTimeX::Lite->new(year=>$y, month=>$mo, day=>$d, hour=>$h,
minute=>$m, second=>$s,time_zone=>$tz);
    $dt->set_time_zone($new_tz);

    return map $dt->$_, qw/year month day hour minute second/;
}

sub convert_timezone_env_c {
    my ($y,$mo,$d,$h,$m,$s,$tz,$new_tz) = @_;
    my $save_tz = Env::C::getenv("TZ");

    Env::C::setenv("TZ",$tz,1);
    my $time = POSIX::mktime($s,$m,$h,$d,$mo-1,$y-1900,0,0,-1);

    Env::C::setenv("TZ",$new_tz,1);
    POSIX::tzset(); # localtime_r bug
    ($s,$m,$h,$d,$mo,$y) = localtime($time);
    $mo++; $y+=1900;

    # this belongs in a destructor
    if (defined $save_tz) { Env::C::setenv("TZ",$save_tz,1) }
    else { Env::C::unsetenv("TZ") }

    return ($y,$mo,$d,$h,$m,$s);
}

sub convert_timezone_system {
    my ($y,$mo,$d,$h,$m,$s,$tz,$new_tz) = @_;

    local $ENV{"TZ"} = $tz;
    my $time = POSIX::mktime($s,$m,$h,$d,$mo-1,$y-1900,0,0,-1);

    $ENV{"TZ"} = $new_tz;
    POSIX::tzset(); # localtime_r bug
    ($s,$m,$h,$d,$mo,$y) = localtime($time);
    $mo++; $y+=1900;

    return ($y,$mo,$d,$h,$m,$s);
}

print join ",",
datetime_lite=>convert_timezone_datetime_lite(2008,7,3,23,2,3,"America/Denver","America/New_York");
print join ",",
datetime=>convert_timezone_datetime(2008,7,3,23,2,3,"America/Denver","America/New_York");
print join ",",
registry=>convert_timezone_env_c(2008,7,3,23,2,3,"America/Denver","America/New_York");
print join ",",
"system"=>convert_timezone_system(2008,7,3,23,2,3,"America/Denver","America/New_York");

use Benchmark "cmpthese";
cmpthese(-5, {
    datetime_lite => sub { my ($y,$mo,$d,$h,$m,$s) =
convert_timezone_datetime_lite(2008,7,3,23,2,3,"America/Denver","America/New_York");
return },
    datetime => sub { my ($y,$mo,$d,$h,$m,$s) =
convert_timezone_datetime(2008,7,3,23,2,3,"America/Denver","America/New_York");
return },
    env_c => sub { my ($y,$mo,$d,$h,$m,$s) =
convert_timezone_env_c(2008,7,3,23,2,3,"America/Denver","America/New_York");
return },
    "system" => sub { my ($y,$mo,$d,$h,$m,$s) =
convert_timezone_system(2008,7,3,23,2,3,"America/Denver","America/New_York");
return },
} );