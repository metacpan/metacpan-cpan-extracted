use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use DateTime::Calendar::Christian;

#########################
# standard reform date (1582-10-04/15 assumed)

my $d = DateTime::Calendar::Christian->new( year  => 2003,
                                            month => 1,
                                            day   => 1,
                                            time_zone => 'floating' );
ok( $d->is_gregorian, '2003 is_gregorian' );
ok( !$d->is_julian, '2003 not is_julian' );

$d = DateTime::Calendar::Christian->new( year  => 1515,
                                         month => 1,
                                         day   => 1,
                                         time_zone => 'floating' );
ok( !$d->is_gregorian, '1515 not is_gregorian' );
ok( $d->is_julian, '1515 is_julian' );

$d = DateTime::Calendar::Christian->new( year  => 1582,
                                         month => 10,
                                         day   => 4,
                                         time_zone => 'floating' );
ok( $d->is_julian, '1582-10-04 is_julian' );
is( $d->ymd, '1582-10-04', '... and correct date' );

$d = DateTime::Calendar::Christian->new( year  => 1582,
                                         month => 10,
                                         day   => 5,
                                         time_zone => 'floating' );
ok( $d->is_julian, '1582-10-05 is_julian' );
is( $d->ymd, '1582-09-25', '... and correct date' );

$d = DateTime::Calendar::Christian->new( year  => 1582,
                                         month => 10,
                                         day   => 15,
                                         time_zone => 'floating' );
ok( $d->is_gregorian, '1582-10-15 is_gregorian' );
is( $d->ymd, '1582-10-15', '... and correct date' );

$d = DateTime::Calendar::Christian->new( year  => 1300,
                                         month => 2,
                                         day   => 29,
                                         time_zone => 'floating' );
ok( $d->is_julian, '1300 is_julian' );
is( $d->ymd, '1300-02-29', '... and leap year' );

eval { $d = DateTime::Calendar::Christian->new( year  => 1700,
                                                month => 2,
                                                day   => 29,
                                                time_zone => 'floating' );
     };
ok( $@, '1700-02-29 is invalid' );

$d = DateTime::Calendar::Christian->new( year  => 1582,
                                         month => 10,
                                         day   => 15,
                                         time_zone => 'floating' );
ok( $d->is_gregorian, '1582-10-15 is_gregorian' );
is( $d->ymd, '1582-10-15', '... and correct date' );

done_testing;

# ex: set textwidth=72 :
