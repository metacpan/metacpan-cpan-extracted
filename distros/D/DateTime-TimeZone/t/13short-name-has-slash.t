use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;

# Some time zone observances in the Olson DB have short names like
# "GMT/BST", which means "alternate between GMT and BST".  This tests
# that the parser does the right thing.
{
    my $dt = DateTime->new(
        year      => 2005, month => 6,
        time_zone => 'Europe/London'
    );

    is( $dt->time_zone_short_name, 'BST', 'time zone short name is BST' );
}

{
    my $dt = DateTime->new(
        year      => 2005, month => 1,
        time_zone => 'Europe/London'
    );

    is( $dt->time_zone_short_name, 'GMT', 'time zone short name is GMT' );
}

done_testing();
