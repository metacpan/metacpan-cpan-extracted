#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use FindBin qw($Bin);

use_ok('Business::TNT::ExpressConnect') or exit;

my $tnt = Business::TNT::ExpressConnect->new({});

my $config;
subtest 'files' => sub {
    ok(-r $tnt->_price_request_in_xsd,  'PriceRequestIN.xsd present');
    ok(-r $tnt->_price_request_out_xsd, 'PriceResponseOUT.xsd present');
    is(ref(eval {$config = $tnt->config}),
        'HASH', 'try to load configuration file');
};

# finished with off-line testing unless username and password set in configuration file
unless ($config->{_}->{username}) {
SKIP: {
        skip 'skipping on-line testing etc/tnt-expressconnect.ini not filled with credentials', 1;
    }
    done_testing();
    exit(0);
}

# finish unless TNT servers are reachable
unless ($tnt->http_ping) {
SKIP: {
        skip 'skipping on-line testing, '
            . $tnt->tnt_get_price_url
            . ' not reachable', 1;
    }
    done_testing();
    exit(0);
}

subtest 'on-line' => sub {

    #data in file
    my $file = $Bin.'/tdata/single_international.xml';
    my $prices = $tnt->get_prices({file => $file});

    is(scalar keys %$prices, 6, 'file upload') || diag join("\n",@{$tnt->errors});

    #data in hash
    my %params = (
        sender             => {country => 'AT', town => 'Vienna',    postcode => 1020},
        delivery           => {country => 'AT', town => 'Schwechat', postcode => '2320'},
        consignmentDetails => {
            totalWeight         => 1.25,
            totalVolume         => 0.1,
            totalNumberOfPieces => 1
        },
    );

    $prices = $tnt->get_prices({params => \%params});
    is(scalar keys %$prices, 4, 'data hash') || diag join("\n",@{$tnt->errors});
};

done_testing();
