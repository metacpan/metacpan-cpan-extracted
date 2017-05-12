use 5.008004;

use strict;
use warnings;

use Test::More tests => 8;
use DateTime::Calendar::Christian;

#########################

my ($rd, $d);

$d = DateTime::Calendar::Christian->new( year  => 1900,
                                         month => 1,
                                         day   => 1 );
ok( ! $d->is_leap_year, '1900 is non-leap' );

$d = DateTime::Calendar::Christian->new( year  => 1500,
                                         month => 1,
                                         day   => 1 );
ok( $d->is_leap_year, '1500 is leap' );

$rd = DateTime->new( year => 1700, month => 2, day => 20 );

$d = DateTime::Calendar::Christian->new( year  => 1700,
                                         month => 1,
                                         day   => 1,
                                         reform_date => $rd );
ok( ! $d->is_leap_year, 'difficult case 1' );

$d = DateTime::Calendar::Christian->new( year  => 1700,
                                         month => 5,
                                         day   => 1,
                                         reform_date => $rd );
ok( ! $d->is_leap_year, 'difficult case 2' );

$rd = DateTime->new( year => 1700, month => 5, day => 20 );

$d = DateTime::Calendar::Christian->new( year  => 1700,
                                         month => 1,
                                         day   => 1,
                                         reform_date => $rd );
ok( $d->is_leap_year, 'difficult case 3' );

$d = DateTime::Calendar::Christian->new( year  => 1700,
                                         month => 10,
                                         day   => 1,
                                         reform_date => $rd );
ok( $d->is_leap_year, 'difficult case 4' );

$rd = DateTime->new( year => 1584, month => 3, day => 5 );

$d = DateTime::Calendar::Christian->new( year  => 1584,
                                         month => 1,
                                         day   => 1,
                                         reform_date => $rd );
ok( ! $d->is_leap_year, 'no leap day during calendar reform' );

$rd = DateTime->new( year => 1700, month => 3, day => 5 );

$d = DateTime::Calendar::Christian->new( year  => 1700,
                                         month => 1,
                                         day   => 1,
                                         reform_date => $rd );
ok( ! $d->is_leap_year, 'no leap day during calendar reform' );

done_testing;

# ex: set textwidth=72 :
