#!/usr/bin/perl -w
use strict;
use lib 'inc';
use vars qw( $class );
use Test::More tests => 3;
use DateTime;

BEGIN {
    $class = 'DateTime::Format::HTTP';
    use_ok $class;
}

require Time::Local if $^O eq "MacOS";
my $offset = ($^O eq "MacOS") ? Time::Local::timegm(0,0,0,1,0,70) : 0;
my $time = (760233600 + $offset);  # assume broken POSIX counting of seconds
$time = DateTime->from_epoch( epoch => $time );

# test time2str
{
    my $out = $class->format_datetime( $time );
    my $wanted = 'Thu, 03 Feb 1994 00:00:00 GMT';
    diag $out;
    diag $wanted;
    is ( $class->format_datetime($time) => $wanted, 'Basic' );
    ok( $class->format_datetime() => 'no param');
}
