use strict;
use Test::More;

use_ok "DateTime::Astro", "moment", "gregorian_components_from_rd";


# simple RD moments

my @dates = (
    [ 732877, 2007, 7, 20 ],
    [ 732109, 2005, 6, 12 ],
    [ 730126, 2000, 1,  7 ],
);

foreach my $data ( @dates ) {
    my $dt = DateTime->new(time_zone => 'UTC',  year => $data->[1], month => $data->[2], day => $data->[3]);
    my $moment = moment( $dt );
    is int($moment), $data->[0], "moment = $moment ($data->[0])";
    my ($y, $m, $d) = gregorian_components_from_rd( int($moment) );
    is $y, $dt->year, "y = $y (" . $dt->year . ")";
    is $m, $dt->month, "m = $m (" . $dt->month . ")";
    is $d, $dt->day, "d = $d (" . $dt->day . ")";
}

done_testing;
