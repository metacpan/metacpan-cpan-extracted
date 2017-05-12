use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
# Simulate locale environment
    $^O = 'hpux';
    $ENV{TZ} = 'MET-1METDST';
}

use DateTime::TimeZone;

TODO: {
    local $TODO = "Fake HP-UX environment, so failing tests are not representative";

    is($ENV{TZ}, 'MET-1METDST');
    is($^O, 'hpux');

    SKIP: {
        my $tz1 = eval { DateTime::TimeZone->new( name => 'local' ) };
        if ($@) {
            diag "local TZ retriving failure: $@";
            skip "FIXME: this should not fail!", 9;
        }

        isa_ok( $tz1, 'DateTime::TimeZone' );
        my $tz2 = DateTime::TimeZone->new( name => 'Europe/Paris' );
        isa_ok( $tz2, 'DateTime::TimeZone' );
        is( $tz1->has_dst_changes, $tz2->has_dst_changes(), 'DST changes' );

        my $tz3 = DateTime::TimeZone->new( name => $tz1->name );
        isa_ok( $tz3, 'DateTime::TimeZone' );
        is( $tz3, $tz1, "Can recreate object from name");


        my $version = '0.1501';
        eval "use DateTime $version";
        skip "Cannot run tests before DateTime.pm $version is installed.", 4 if $@;

        my @dt = (
            {
                year => 2009, month => 3, day => 29,
                hour => 0, minute => 59,
                time_zone => 'UTC'
            }, {
                year => 2009, month => 3, day => 29,
                hour => 1, minute =>  1,
                time_zone => 'UTC'
            }, {
                year => 2009, month => 10, day => 25,
                hour => 1, minute => 59,
                time_zone => 'UTC'
            }, {
                year => 2009, month => 10, day => 25,
                hour => 2, minute =>  1,
                time_zone => 'UTC'
            }
        );

        foreach my $dt_args (@dt) {
            my $dt = DateTime->new(%$dt_args);
            my $dt_txt = $dt->iso8601 . "Z";
            $dt->set_time_zone($tz1);
            my $hour1 = $dt->hour;
            $dt->set_time_zone($tz2);
            my $hour2 = $dt->hour;
            is( $hour1, $hour2, "Same local hour for $dt_txt: $hour1");
        }
    }
}

# vim: set et ts=4 sts=4 sw=4 :
