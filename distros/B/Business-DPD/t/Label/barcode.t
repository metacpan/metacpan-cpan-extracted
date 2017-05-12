use 5.010;
use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use Business::DPD;
use Business::DPD::Label;
my $dpd = Business::DPD->new;
$dpd->connect_schema;
my $label = Business::DPD::Label->new($dpd,{
    zip             => '12555',
    country         => 'DE',
    depot           => '0190',
    serial          => '5002345615',
    service_code    => '101',
});

$label->calc_tracking_number;
$label->calc_routing;
$label->calc_target_country_code;
$label->calc_barcode;

is($label->code,'001255501905002345615101276','code');
is($label->code_barcode,'%001255501905002345615101276','code barcode');
is($label->code_human,'001255501905002345615101276Z','code human readable');

