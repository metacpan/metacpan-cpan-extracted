#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use MooseX::Params::Validate;

use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = use_module('Test::Business::CyberSource')->new;

my $client      = $t->resolve( service => '/client/object'      );
my $billto      = $t->resolve( service => '/helper/bill_to'   );

my $salec = use_module('Business::CyberSource::Request::Sale');

subtest "Visa" => sub {
    test_successful_sale({ card_type => 'visa' });
};

subtest "American Express" => sub {
    test_successful_sale({ card_type => 'amex' });
};

subtest "MasterCard" => sub {
    test_successful_sale({ card_type => 'mastercard' });
};

subtest "Discover" => sub {
    test_successful_sale({ card_type => 'discover' });
};

sub test_successful_sale {
    my (%args) = validated_hash(
        \@_,
        card_type => { isa => 'Str' },
    );

    my $req
        = new_ok( $salec => [{
            reference_code  => 'test-sale-reject-' . time,
            card            => $t->resolve(
                service => '/helper/card_' . $args{card_type}
            ),
            bill_to         => $billto,
            purchase_totals => {
                total    => 3000.01,
                discount => 15.00,
                duty     => 7.00,
                currency => 'USD',
            },
        }]);

    my $ret = $client->submit( $req );

    is( $ret->decision,             'ACCEPT', 'check decision'       );
    is( $ret->reason_code,           100,     'check reason_code'    );
    is( $ret->currency,             'USD',    'check currency'       );
    is( $ret->auth->amount,         '3000.01',    'check amount'     );
    is( $ret->auth->avs_code, 'Y', 'check avs_code' );
    is( $ret->auth->avs_code_raw,   'Y',       'check avs_code_raw'  );
    is( $ret->auth->processor_response, '00',  'check processor_response');
    is( $ret->reason_text, 'Successful transaction', 'check reason_text' );
    is( $ret->auth->auth_code, '841000',     'check auth_code exists');

    ok( $ret->request_id,          'check request_id exists'    );
    ok( $ret->request_token,       'check request_token exists' );
    ok( $ret->auth->datetime,      'check datetime exists'      );
    ok( $ret->auth->auth_record,   'check auth_record exists'   );
    ok( $ret->auth->reconciliation_id, 'reconciliation_id exists' );

    return;
}

done_testing;
