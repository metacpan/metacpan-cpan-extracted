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
	login       => $ENV{PERL_BUSINESS_BACKOFFICE_USERNAME},
	password    => $ENV{PERL_BUSINESS_BACKOFFICE_PASSWORD},
	debug       => $ENV{PERL_BUSINESS_BACKOFFICE_DEBUG},
	type        => 'CC',
	action      => 'Normal Authorization',
	amount      => 1.00,
	currency    => 'USD',
	name        => 'Caleb Cushing',
	card_number => '5454545454545454',
	expiration  => '1215',
	cvv2        => '111',
);

$tx->submit;

ok $tx->is_success, 'successful';

done_testing;
