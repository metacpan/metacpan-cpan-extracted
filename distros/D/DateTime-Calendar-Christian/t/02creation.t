use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use DateTime::Calendar::Christian;

#########################

# reform date
my $r = DateTime->new( year  => 2000,
                       month => 1,
                       day   => 1,
                       time_zone => 'floating' );

my $d = DateTime::Calendar::Christian->new( year  => 2003,
                                            month => 1,
                                            day   => 1,
                                            time_zone => 'floating' );
ok($d, 'date creation (default reform_date)');
is($d->ymd, '2003-01-01', 'correct date');

my $d2 = $d->clone;
is($d2->ymd, '2003-01-01', 'clone');

my $dr = $d->reform_date;
is($dr && $dr->ymd, '1582-10-15', 'correct (default) reform date');

$d = DateTime::Calendar::Christian->new( year  => 2003,
                                         month => 1,
                                         day   => 1,
                                         time_zone => 'floating',
                                         reform_date => $r );

$dr = $d->reform_date;
is($dr && $dr->ymd, '2000-01-01', 'correct (explicit) reform date');

$d2 = $d->new( year  => 2002,
               month => 1,
               day   => 1,
               time_zone => 'floating' );

$dr = $d2->reform_date;
is($dr && $dr->ymd, '2000-01-01', 'correct reform date (from object)');

$d = DateTime::Calendar::Christian->new( reform_date => $r );
ok( $d, '"date generator" creation' );

$dr = $d->reform_date;
is($dr && $dr->ymd, '2000-01-01', 'correct reform date (date generator)');

$d2 = $d->new( year  => 2002,
               month => 1,
               day   => 1,
               time_zone => 'floating' );

$dr = $d2->reform_date;
is($dr && $dr->ymd, '2000-01-01', 'correct reform date (from date generator)');

$d = DateTime::Calendar::Christian->new( year  => 2003,
                                         month => 1,
                                         day   => 1,
                                         time_zone => 'floating',
                                         reform_date => 'Utrecht' );
is($d->reform_date->ymd, '1700-12-12', "reform date 'Utrecht'");

is( DateTime::Calendar::Christian->new( reform_date => '2000-1-1'
    )->reform_date->ymd, '2000-01-01', 'reform date as ISO-8601-ish string' );

done_testing;

# ex: set textwidth=72 :
