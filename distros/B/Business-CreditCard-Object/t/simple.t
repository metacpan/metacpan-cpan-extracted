#!/usr/bin/perl -w

use strict;
use Business::CreditCard::Object;
use Test::More tests => 26;

my %test_data = (
	"4929-4929-4929-4928" => "",
	"4929-4929-4929-4929" => "VISA card",
	"4929 4929 4929 4929" => "VISA card",
	"4929-4929 4929-4929" => "VISA card",
	'4929-492-492-497' => 'VISA card',
	'5454545454545454' => 'MasterCard',
);

while (my ($no, $type) = each %test_data) { 
	my $card = Business::CreditCard::Object->new($no);
	if (!$type) { 
		ok !$card->is_valid, "$no is not valid";
		next;
	}
	ok $card->is_valid, "$card is valid" ;
	ok length $card->number, "$card has a number";
	is "$card", $card->number, "$card stringifies";
	unlike $card->number, qr/\D/, "$card is all digits";
	is $card->type, $type, "$card is $type";
}

