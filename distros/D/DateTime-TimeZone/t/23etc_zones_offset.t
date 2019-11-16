use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;
use Test::Fatal;

my %tz_to_offset = (
    'Etc/GMT-0'   => 0,
    'etc/gmt-0'   => 0,
    'Etc/GMT+1'   => 3600,
    'Etc/GMT+12'  => 43200,
    'Etc/GMT-1'   => -3600,
    'Etc/GMT-14'  => -50400,
    'Etc/GMT-20'  => undef,
    'Etc/GMT-999' => undef,
    'Etc/UTC+7'   => 25200,
    'etc/utc+7'   => 25200,
    'Etc/UTC-9'   => -32400,
    'Etc/UTC+20'  => undef,
);

for my $tz ( sort keys %tz_to_offset ) {
    if ( defined $tz_to_offset{$tz} ) {
        my $dt = DateTime::TimeZone->new( name => $tz );
        is(
            $dt->offset_for_datetime,
            $tz_to_offset{$tz},
            "$tz matches offset"
        );
    }
    else {
        like(
            exception { DateTime::TimeZone->new( name => $tz ) },
            qr/Invalid/i,
            "$tz is invalid"
        );
    }
}

done_testing();
