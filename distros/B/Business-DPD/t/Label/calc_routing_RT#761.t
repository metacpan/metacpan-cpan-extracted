use 5.010;
use strict;
use warnings;

use Test::More tests => 8;
use Test::NoWarnings;
use Test::Exception;

use Business::DPD;
use Business::DPD::Label;
my $dpd = Business::DPD->new;
$dpd->connect_schema;

{
    my $label = Business::DPD::Label->new(
        $dpd,
        {   zip          => '70734',
            country      => 'DE',
            depot        => '0190',
            serial       => '5002345615',
            service_code => '101',
        }
    );

    $label->calc_routing;

    is( $label->o_sort,  '05',   'o_sort' );
    is( $label->d_sort,  '37',   'd_sort' );
    is( $label->d_depot, '0171', 'd_depot' );
}

{
    my $label = Business::DPD::Label->new(
        $dpd,
        {   zip          => '70734',
            country      => 'DE',
            depot        => '0190',
            serial       => '5002345615',
            service_code => '179',
        }
    );

    $label->calc_routing;

    is( $label->o_sort,  '17',   'o_sort' );
    is( $label->d_sort,  'P22',  'd_sort' );
    is( $label->d_depot, '0173', 'd_depot' );
}

{
    my $label = Business::DPD::Label->new(
        $dpd,
        {   zip          => '70734',
            country      => 'DE',
            depot        => '0190',
            serial       => '5002345615',
            service_code => '102',
        }
    );

    throws_ok {
        $label->calc_routing;
    }
    qr/No route found!/, 'No route found for this service code';
}

