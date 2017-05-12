use strict;
use warnings;
use Test::More;
use Business::OnlinePayment;

plan skip_all => 'PERL_BUSINESS_BACKOFFICE_USERNAME and/or'
	. 'PERL_BUSINESS_BACKOFFICE_PASSWORD not defined in ENV'
	unless defined $ENV{PERL_BUSINESS_BACKOFFICE_USERNAME}
	&& defined $ENV{PERL_BUSINESS_BACKOFFICE_PASSWORD};

my $tx = new_ok( 'Business::OnlinePayment' => [ 'PaperlessTrans' ]);

isa_ok $tx, 'Business::OnlinePayment::PaperlessTrans';

$tx->test_transaction(1);

$tx->content(
	login          => $ENV{PERL_BUSINESS_BACKOFFICE_USERNAME},
	password       => $ENV{PERL_BUSINESS_BACKOFFICE_PASSWORD},
	debug          => $ENV{PERL_BUSINESS_BACKOFFICE_DEBUG},
	type           => 'ECHECK',
	action         => 'Normal Authorization',
	check_number   => '132',
	amount         => 1.32,
	routing_code   => '222222226',
	account_number => '42222226',
	currency       => 'USD',
	account_name   => 'Caleb Cushing',
	name           => 'Caleb Cushing',
	address        => '400 E. Royal Lane #201',
	city           => 'Irving',
	state          => 'TX',
	zip            => '75039-2291',
	country        => 'US',
);

$tx->submit;

ok ! $tx->is_success, 'request not successful';

done_testing;
