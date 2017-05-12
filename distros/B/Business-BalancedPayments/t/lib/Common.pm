package t::lib::Common;

use Business::BalancedPayments;
use Exporter qw(import);
use Test::More import => [qw(plan)];

our @EXPORT_OK = qw(
    bp_v10 bp_v11 create_card create_test_bank skip_unless_has_secret
);

my $test_card = {
    number           => '5105105105105100',
    expiration_month => 12,
    expiration_year  => 2020,
    name             => 'John Smith',
};

my $test_bank = {
    account_number => '000123456789',
    acount_type    => 'checking',
    name           => 'Banker Name',
    routing_number => '110000000',
    address => {
        line1       => '123 Abc St',
        postal_code => '94103',
    },
};

sub bp_v10 {
    return Business::BalancedPayments->client(
        secret  => secret(),
        version => 1.0,
    );
}

sub bp_v11 {
    return Business::BalancedPayments->client(
        secret  => secret(),
        version => 1.1,
    );
}

sub secret { $ENV{PERL_BALANCED_TEST_SECRET} }

sub skip_unless_has_secret {
    plan skip_all => 'PERL_BALANCED_TEST_SECRET is required' unless secret();
}

sub create_card { bp_v11->create_card($test_card) }

sub create_test_bank { bp_v11->create_bank_account($test_bank) }

1;
