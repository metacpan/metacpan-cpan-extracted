#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/04.compare.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

my $dt1 = DateTime::Lite->new( year => 2025, month => 1, day => 1,  time_zone => 'UTC' );
my $dt2 = DateTime::Lite->new( year => 2025, month => 6, day => 15, time_zone => 'UTC' );
my $dt3 = DateTime::Lite->new( year => 2025, month => 1, day => 1,  time_zone => 'UTC' );

# NOTE: compare()
subtest 'compare()' => sub
{
    is( DateTime::Lite->compare( $dt1, $dt2 ), -1, 'compare: dt1 < dt2 returns -1' );
    is( DateTime::Lite->compare( $dt2, $dt1 ),  1, 'compare: dt2 > dt1 returns 1' );
    is( DateTime::Lite->compare( $dt1, $dt3 ),  0, 'compare: equal returns 0' );
};

# NOTE: Overloaded <=>
subtest 'Overloaded <=>' => sub
{
    ok( $dt1 < $dt2,   'dt1 < dt2' );
    ok( $dt2 > $dt1,   'dt2 > dt1' );
    ok( $dt1 == $dt3,  'dt1 == dt3 (equal)' );
    ok( $dt1 <= $dt3,  'dt1 <= dt3' );
    ok( $dt2 >= $dt1,  'dt2 >= dt1' );
    ok( $dt1 != $dt2,  'dt1 != dt2' );
};

# NOTE: String comparison via ""
subtest 'String comparison via ""' => sub
{
    ok( "$dt1" lt "$dt2", 'string lt' );
    ok( "$dt1" eq "$dt3", 'string eq for equal datetimes' );
};

# NOTE: is_between
subtest 'is_between' => sub
{
    my $mid = DateTime::Lite->new( year => 2025, month => 3, day => 1, time_zone => 'UTC' );
    ok( $mid->is_between( $dt1, $dt2 ), 'March 1 is between Jan 1 and Jun 15' );
    ok( !$dt1->is_between( $dt1, $dt2 ), 'dt1 is not strictly between itself and dt2' );
};

# NOTE: Sorting
subtest 'Sorting' => sub
{
    my $mid    = DateTime::Lite->new( year => 2025, month => 3, day => 1, time_zone => 'UTC' );
    my @dates  = ( $dt2, $dt1, $mid );
    my @sorted = sort{ DateTime::Lite->compare( $a, $b ) } @dates;
    is( $sorted[0]->month, 1, 'sort: first is January' );
    is( $sorted[1]->month, 3, 'sort: second is March' );
    is( $sorted[2]->month, 6, 'sort: third is June' );
};

done_testing;

__END__
