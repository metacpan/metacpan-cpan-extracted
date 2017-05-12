use strict;
BEGIN { $^W = 1 }

use Test::More tests => 3;
use DateTime::Calendar::Pataphysical;

#########################

my $dt = DateTime::Calendar::Pataphysical->new(
            year => 130, month => 2, day => 10);

$dt->truncate( to => 'day' );
is( $dt->ymd, '130-02-10', 'truncate to day' );

$dt->truncate( to => 'month' );
is( $dt->ymd, '130-02-01', 'truncate to month' );

$dt->truncate( to => 'year' );
is( $dt->ymd, '130-01-01', 'truncate to year' );
