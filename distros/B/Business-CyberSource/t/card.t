use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Fatal;
use Test::Deep;
use Test::Method;

use Module::Runtime qw( use_module );
use DateTime;

my $card_c = use_module('Business::CyberSource::RequestPart::Card');

my @test_pairs = (
	[ qw( 4111111111111111 001 VISA       ) ],
	[ qw( 5555555555554444 002 MASTERCARD ) ],
	[ qw( 3566111111111113 004 DISCOVER   ) ],
);

my $dt0 = DateTime->new( year => 2025, month => 4, day => 30 );
my $dt1 = DateTime->new( year => 2025, month => 5, day => 1  );
my $dt2 = DateTime->new( year => 2025, month => 5, day => 2  );
my $dt3 = DateTime->new( year => 2025, month => 6, day => 1  );

foreach ( @test_pairs ) {
	my ( $acct_num, $type_code, $type ) = @{ $_ };

	my $card
		= new_ok( $card_c => [{
			account_number => $acct_num,
			security_code  => '1111',
			expiration     => {
				year  => '2025',
				month => '04',
			},
	}]);

	my $expected_card = {
		accountNumber   => $acct_num,
		cardType        => $type_code,
		expirationMonth => 4,
		expirationYear  => 2025,
		cvIndicator     => 1,
		cvNumber        => 1111,
	};

	isa_ok  $card->expiration, 'DateTime';
	does_ok $card, 'MooseX::RemoteHelper::CompositeSerialization';
	can_ok  $card, 'serialize';

	method_ok $card, type              => [], $type;
	method_ok $card, card_type_code    => [], $type_code;
	method_ok $card, security_code     => [],  1111;
	method_ok $card, is_expired        => [], bool(0);
	method_ok $card->expiration, month => [], 4,    'expiraton';
	method_ok $card->expiration, year  => [], 2025, 'expiraton';
	method_ok $card->expiration, day   => [], 30,   'expiraton';
	method_ok $card, serialize         => [], $expected_card;

	# if $dt was $now then card would be
	method_ok $card, _compare_date_against_expiration => [$dt0], bool(0), '4/30 isnt expired';
	method_ok $card, _compare_date_against_expiration => [$dt1], bool(0), '5/1 isnt expired';
	method_ok $card, _compare_date_against_expiration => [$dt2], bool(1), '5/2 is expired';
	method_ok $card, _compare_date_against_expiration => [$dt3], bool(1), '6/1 is expired';
}

done_testing;
