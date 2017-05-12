#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Deep;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'Data::Header::Fields' ) or exit;
}

exit main();

sub main {
	my $header1 = "t:123\nt2:321\n 123\nt3:999\n";
	my $lines = Data::Header::Fields->decode($header1);

	my @lines_expect = (
		(bless { key => 't', value => Data::Header::Fields::Value->new('value' => "123\n",), parent => 'Data::Header::Fields', original_line => "t:123\n"}, 'Data::Header::Fields::Line'),
		(bless { key => 't2', value => Data::Header::Fields::Value->new('value' => "321\n 123\n"), parent => 'Data::Header::Fields', original_line => "t2:321\n 123\n"}, 'Data::Header::Fields::Line'),
		(bless { key => 't3', value => Data::Header::Fields::Value->new('value' => "999\n"), parent => 'Data::Header::Fields', original_line => "t3:999\n"}, 'Data::Header::Fields::Line'),
	);
	@lines_expect = map { $_->value->parent($_) } @lines_expect;

	cmp_deeply(
		$lines,
		\@lines_expect,
		'decode()',
	);
	eq_or_diff(Data::Header::Fields->encode($lines), $header1, 'encode()');

	cmp_deeply(
		{
			map {
				my ($key, $value) = ($_->key, $_->value);
				chomp $value;
				($key => $value.'');
			} @{$lines}
		},
		{
			't'  => "123",
			't2' => "321 123",
			't3' => "999",
		},
		'decode()',
	);

	cmp_ok(
		Data::Header::Fields->new->decode($header1),
		'eq',
		$header1,
		'overloaded stringify',
	);

	cmp_deeply(
		[ Data::Header::Fields->keys($lines) ],
		[ 't', 't2', 't3'],
		'keys()',
	);
	
	my $header2 = "t1:a123\nt2:b321\n 123\nt3:c999\n";
	my $dhf = Data::Header::Fields->new()->decode(\$header2);
	cmp_ok($dhf->get_value('t1'), 'eq', 'a123', 'get_value()');
	cmp_ok($dhf->get_value('t2'), 'eq', 'b321 123', 'get_value()');
	cmp_ok($dhf->get_value('t3'), 'eq', 'c999', 'get_value()');
	ok(!defined $dhf->get_value('qwe'), 'get_value() - unknown');
	
	cmp_ok($dhf->set_value('t1' => '\o/')->get_value('t1'), 'eq', '\o/', 'set_field() update');
	cmp_ok($dhf->set_value('t3' => 'd999')->get_value('t3'), 'eq', 'd999', 'set_field() update');
	cmp_ok($dhf->set_value('t5' => '0:1:2:3:4:5')->get_value('t5'), 'eq', '0:1:2:3:4:5', 'set_field() new entry with ":"');
	cmp_ok($dhf->set_value('tx' => 'yyy')->get_value('tx'), 'eq', 'yyy', 'set_field() new entry');

	eq_or_diff(
		$dhf->encode(),
		"t1:\\\\o/\nt2:b321\n 123\nt3:d999\nt5:0:1:2:3:4:5\ntx:yyy\n",
		'encode() it now',
	);
	
	$dhf->rm_fields('t5', 't2', 't1');
	eq_or_diff(
		$dhf->encode(),
		"t3:d999\ntx:yyy\n",
		'encode() after rm',
	);

	# escape characters
	my $dhf_esc = Data::Header::Fields->new();
	cmp_ok(
		$dhf_esc->set_value('n' => "1\n2\n3\n")->get_value('n'),
		'eq',
		"1\n2\n3\n",
		'multiline',
	);
	eq_or_diff(
		$dhf_esc->encode(),
		"n:1\\n2\\n3\\n\n",
		'encode() it now',
	);
	eq_or_diff(
		Data::Header::Fields->new->decode(\$dhf_esc->encode())->encode(),
		"n:1\\n2\\n3\\n\n",
		'encode(),decode(),encode() roundtrip',
	);
	cmp_ok(
		Data::Header::Fields->new->decode(\$dhf_esc->encode())->get_value('n'),
		'eq',
		"1\n2\n3\n",
		'multiline',
	);
	
	# from rfc2822
	my $rfc2822_2_2_3_01 = "Subject: This is a test\n";
	my $rfc2822_2_2_3_02 = "Subject: This\n is a test\n";

	cmp_ok(
		Data::Header::Fields->new()->decode(\$rfc2822_2_2_3_01)->get_value('Subject'),
		'eq',
		' This is a test',
		'http://tools.ietf.org/html/rfc2822#section-2.2.3'
	);
	cmp_ok(
		Data::Header::Fields->new()->decode(\$rfc2822_2_2_3_01)->get_value('Subject'),
		'eq',
		Data::Header::Fields->new()->decode(\$rfc2822_2_2_3_02)->get_value('Subject'),
		'http://tools.ietf.org/html/rfc2822#section-2.2.3'
	);
	
	# from rfc5545
	my $rfc5545_3_1_01 = "DESCRIPTION:This is a long description that exists on a long line.\n";
	my $rfc5545_3_1_02 = "DESCRIPTION:This is a lo\n ng description\n  that exists on a long line.\n";

	cmp_ok(
		Data::Header::Fields->new(tight_folding => 1)->decode(\$rfc5545_3_1_01)->get_value('DESCRIPTION'),
		'eq',
		'This is a long description that exists on a long line.',
		'http://tools.ietf.org/html/rfc5545#section-3.1'
	);
	cmp_ok(
		Data::Header::Fields->new(tight_folding => 1)->decode(\$rfc5545_3_1_01)->get_value('DESCRIPTION'),
		'eq',
		Data::Header::Fields->new(tight_folding => 1)->decode(\$rfc5545_3_1_02)->get_value('DESCRIPTION'),
		'http://tools.ietf.org/html/rfc5545#section-3.1'
	);
	
	return 0;
}

