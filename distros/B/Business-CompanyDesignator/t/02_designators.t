#!perl

use Test::More;
use Business::CompanyDesignator;
use Data::Dump qw(dd pp dump);

my ($bcd, $data, @des, $nlong, $nabbrev, $ndes);

ok($bcd = Business::CompanyDesignator->new, 'constructor ok');
ok($data = $bcd->data, 'data method ok');
#dd $data;
ok(@des = $bcd->long_designators, 'long_designators method ok, found ' . ($nlong = scalar(@des)));
ok(@des = $bcd->abbreviations, 'abbreviations method ok, found ' . ($nabbrev = scalar(@des)));
ok(@des = $bcd->designators, 'designators method ok, found ' . ($ndes = scalar(@des)));
is($ndes, $nlong + $nabbrev, 'designator count = long + abbrev');

done_testing;

