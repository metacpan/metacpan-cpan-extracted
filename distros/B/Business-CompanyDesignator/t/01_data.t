#!perl

use Test::More;
use Business::CompanyDesignator;
use Data::Dump qw(dd pp dump);

my ($bcd, $datafile, $data);

ok($bcd = Business::CompanyDesignator->new, 'constructor ok');
ok($datafile = $bcd->datafile, "datafile method ok: $datafile");
ok($data = $bcd->data, 'data method ok');
#dd $data;

done_testing;

