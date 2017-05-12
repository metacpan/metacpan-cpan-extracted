#!perl

use strict;
use warnings;

use Chess::FIDE;
use Test::More tests => 9;

my $fide = Chess::FIDE->new();

my @tests = (
	{
		input => 'A. Ashakirani Devi',
		output => {
			'givenname' => 'A. Ashakirani',
			'name' => 'A. Ashakirani Devi',
			'fidename' => 'A. Ashakirani Devi',
			'surname' => 'Devi'
		},
	},
	{
		input => 'A B, Muhammad Yusop',
		output => {
			'givenname' => 'Muhammad Yusop',
			'surname' => 'A B',
			'fidename' => 'A B, Muhammad Yusop',
			'name' => 'Muhammad Yusop A B'
		},
	},
	{
		input => 'A, Suria, Affendi',
		output => {
			'surname' => 'A, Suria',
			'givenname' => 'Affendi',
			'name' => 'Affendi A, Suria',
			'fidename' => 'A, Suria, Affendi'
		},
	},
	{
		input => 'Andreikin, Dmitry',
		output => {
			'surname' => 'Andreikin',
			'givenname' => 'Dmitry',
			'name' => 'Dmitry Andreikin',
			'fidename' => 'Andreikin, Dmitry'
		},
	},
	{
		input => ', Vardharajan',
		output => {
			'surname' => 'Vardharajan',
			'givenname' => 'Vardharajan',
			'name' => 'Vardharajan',
			'fidename' => ', Vardharajan'
		},
	},
	{
		input => 'A.sameeaa, Mohamed H.',
		output => {
			'surname' => 'A.sameeaa',
			'givenname' => 'Mohamed H.',
			'name' => 'Mohamed H. A.sameeaa',
			'fidename' => 'A.sameeaa, Mohamed H.'
		},
	},
	{
		input => 'Aabling-Thomsen, Jakob',
		output => {
			'surname' => 'Aabling-Thomsen',
			'givenname' => 'Jakob',
			'name' => 'Jakob Aabling-Thomsen',
			'fidename' => 'Aabling-Thomsen, Jakob'
		},
	},
	{
		input => 'A. Md. Imran',
		output => {
			'surname' => 'Imran',
			'givenname' => 'A. Md.',
			'name' => 'A. Md. Imran',
			'fidename' => 'A. Md. Imran'
		},
	},
	{
		input => '',
		output => {
			name => '',
		},
	},
);

for my $test (@tests) {
	my %info = (name => $test->{input});
	$fide->parseName(\%info);
	is_deeply(\%info, $test->{output}, "name $test->{input} parsed correctly");
}
