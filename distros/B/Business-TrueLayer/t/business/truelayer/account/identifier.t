#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Account::Identifier' );

my $Identifier = Business::TrueLayer::Account::Identifier->new(
    'account_number' => '00033171',
    'sort_code' => '040668',
    'type' => 'sort_code_account_number'
);

isa_ok(
    $Identifier,
    'Business::TrueLayer::Account::Identifier',
);

is( $Identifier->type,'sort_code_account_number','->type' );
is( $Identifier->sort_code,'040668','->sort_code' );
is( $Identifier->account_number,'00033171','->account_number' );

done_testing();
