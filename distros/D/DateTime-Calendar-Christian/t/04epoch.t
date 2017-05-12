use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use DateTime::Calendar::Christian;

#########################

my $r = DateTime->new( year => 2003, month => 1, day => 1 );

SKIP: {
    skip 'not UNIX', 4 unless gmtime(0) eq 'Thu Jan  1 00:00:00 1970';
    my $d = DateTime::Calendar::Christian->from_epoch( epoch => 0 );
    is( $d->epoch, 0, 'epoch 0' );
    is( $d->ymd, '1970-01-01', 'epoch is correct' );

    $d = DateTime::Calendar::Christian->from_epoch( epoch => 1e9 );
    is( $d->epoch, 1e9, 'epoch 1e9' );
    is( $d->ymd, '2001-09-09', 'epoch is correct' );

    $d = DateTime::Calendar::Christian->from_epoch( epoch => 0,
                                                    reform_date => $r );
    is( $d->epoch, 0, 'epoch 0 (Julian)' );
    is( $d->ymd, '1969-12-19', 'epoch is correct (Julian)' );
}

my $d = DateTime::Calendar::Christian->now( reform_date => $r );
isa_ok( $d, 'DateTime::Calendar::Christian' );

done_testing;

# ex: set textwidth=72 :
