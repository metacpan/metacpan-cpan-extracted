use strict;
use Test::More;

use_ok "DateTime::Astro", "moment", "gregorian_year_from_rd";


for my $selected_y ( 1, 99, 389, 1900, 2000 ) {
    my $dt = DateTime->new(time_zone => 'UTC', year => $selected_y, month => 1, day => 1);
    for (1..1000) {
        my $moment = moment( $dt );
        my $y = gregorian_year_from_rd( int( $moment ) );

        is $y, $dt->year, "dt = $dt, moment = $moment, got year = $y";
        $dt->add(days => 1);
    }
}

done_testing;
