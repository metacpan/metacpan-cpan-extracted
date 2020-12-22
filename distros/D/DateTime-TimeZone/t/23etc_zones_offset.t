use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;
use Test::Fatal;

my $dt = DateTime->new( year => 2020 );

for my $h ( 0 .. 14 ) {
    for my $zone (qw( GMT UTC )) {
        for my $sign (qw( + - )) {
            my $name   = "Etc/$zone$sign$h";
            my $expect = $h * 3600;
            $expect *= -1 if $sign eq '+';
            my $tz = DateTime::TimeZone->new( name => $name );
            is(
                $tz->offset_for_datetime($dt),
                "$expect",
                "$name offset is $expect",
            );
        }
    }
}

for my $bad (qw( Etc/UTC+15 Etc/GMT-15 Etc/UTC+999 )) {
    like(
        exception { DateTime::TimeZone->new( name => $bad ) },
        qr/\Q'$bad'\E is an invalid name/,
        "$bad is an invalid time zone",
    );
}

done_testing();
