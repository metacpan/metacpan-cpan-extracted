use 5.010;
use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;
use Test::Exception;

use Business::DPD;
my $dpd = Business::DPD->new;

is($dpd->iso7064_mod37_36_checksum('01905002345614'),'0','checksum 0');
is($dpd->iso7064_mod37_36_checksum('01905002345615'),'Y','checksum Y');
is($dpd->iso7064_mod37_36_checksum('004782901905002679885101276'),'6','checksum Y');

dies_ok (sub { $dpd->iso7064_mod37_36_checksum('00ö')},'only ascii');

