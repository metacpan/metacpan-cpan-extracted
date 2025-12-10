#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use FindBin qw/ $Bin /;
use Test::Warnings;

use_ok( 'Business::NAB::Australian::DirectEntry::Payments' );
use_ok( 'Business::NAB::BPAY::Payments' );

my $Payments = Business::NAB::Australian::DirectEntry::Payments->new;

# attributes should be scoped to their class and not
# to the abstract class
lives_ok(
    sub {
        $Payments->add_detail_record( {
            bsb_number           => '083-047',
            account_number       => 123456789,
            transaction_code     => '13',
            amount               => 1,
            title_of_account     => " Beneficiary 1",
            lodgement_reference  => 'FOR DEMONSTRATION',
            bsb_number_trace     => '083-047',
            account_number_trace => '123456789',
            remitter_name        => 'NAB SAMPLE  TEST',
            withholding_tax      => '00000000',
        } );
    },
    '->add_detail_record lives',
);

done_testing();
