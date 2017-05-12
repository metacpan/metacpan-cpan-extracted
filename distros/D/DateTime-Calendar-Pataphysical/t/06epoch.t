use strict;
BEGIN { $^W = 1 }

use Test::More tests => 3;
use DateTime::Calendar::Pataphysical;

#########################

SKIP: {
    skip 'not UNIX', 4 unless gmtime(0) eq 'Thu Jan  1 00:00:00 1970';
    my $d = DateTime::Calendar::Pataphysical->from_epoch( epoch => 0 );
    is( $d->ymd, '097-05-04', 'epoch 0 is correct' );

    $d = DateTime::Calendar::Pataphysical->from_epoch( epoch => 1e9 );
    is( $d->ymd, '129-01-02', 'epoch 1e9 is correct' );
}

my $d = DateTime::Calendar::Pataphysical->now;
isa_ok( $d, "DateTime::Calendar::Pataphysical" );
