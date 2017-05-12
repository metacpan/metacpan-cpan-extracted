use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;

use DateTime::TimeZone;
use Try::Tiny;

for my $name (
    qw( EST MST HST CET EET MET WET EST5EDT CST6CDT MST7MDT PST8PDT )) {
    my $tz = try { DateTime::TimeZone->new( name => $name ) };
    ok( $tz, "got a timezone for name => $name" );
}

done_testing();
