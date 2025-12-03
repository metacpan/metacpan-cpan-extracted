#!perl -T

use 5.008;
use strict;
use warnings;

my $verbose = 0;

#### nothing to change below
use utf8; # we have unicode strings in this file

our $VERSION='0.31';

use Test::More;
use Test2::Plugin::UTF8;
#use Test::Deep;

use Data::Roundtrip qw/:json perl2dump/;

my ($false, $true, $popo);

for my $jsonstr (
	'{"hello":1, "bt":true, "bf":false}',
	'{"γειά σας":1, "bt":true, "bf":false}',
){
	($false, $true) = (13, 12);
	$popo = Data::Roundtrip::json2perl(
		$jsonstr,
		{'boolean_values'=>[$false, $true]}
	);
	ok(defined $popo, 'json2perl()'." : called and got good result.") or BAIL_OUT;
	is($popo->{'bt'}, $true, 'json2perl()'." : result has true value mapped to $true.") or BAIL_OUT(perl2dump($popo)."no, see above results.");
	is($popo->{'bf'}, $false, 'json2perl()'." : result has false value mapped to $false.") or BAIL_OUT(perl2dump($popo)."no, see above results.");

	($false, $true) = ('abc', 'xyz');
	$popo = Data::Roundtrip::json2perl(
		$jsonstr,
		{'boolean_values'=>[$false, $true]}
	);
	ok(defined $popo, 'json2perl()'." : called and got good result.") or BAIL_OUT;
	is($popo->{'bt'}, $true, 'json2perl()'." : result has true value mapped to $true.") or BAIL_OUT(perl2dump($popo)."no, see above results.");
	is($popo->{'bf'}, $false, 'json2perl()'." : result has false value mapped to $false.") or BAIL_OUT(perl2dump($popo)."no, see above results.");

	# restore default boolean mapping
	$popo = Data::Roundtrip::json2perl(
		$jsonstr,
		{'boolean_values'=>[]}
	);
	ok(defined $popo, 'json2perl()'." : called and got good result.") or BAIL_OUT;
	is(ref($popo->{'bt'}), 'JSON::PP::Boolean', 'json2perl()'." : result has true value mapped to $true.") or BAIL_OUT(perl2dump($popo)."no, see above results.");
	is(ref($popo->{'bf'}), 'JSON::PP::Boolean', 'json2perl()'." : result has false value mapped to $false.") or BAIL_OUT(perl2dump($popo)."no, see above results.");
}
done_testing;
