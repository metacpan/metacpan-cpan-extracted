# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 13;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $stor = Cv::MemStorage->new();
ok($stor->isa('Cv::MemStorage'));

if (1) {
	my $hw = "hello, world";
	my $s = $stor->allocString($hw);
	isa_ok($s, 'Cv::String');
	can_ok($s, 'ptr');
	is($s->ptr, $hw);
	can_ok($s, 'len');
	is($s->len, length($hw));
}

if (2) {
	my $hw = "\0hello, world";
	my $s = $stor->allocString($hw);
	isa_ok($s, 'Cv::String');
	can_ok($s, 'ptr');
	is($s->ptr, $hw);
	can_ok($s, 'len');
	is($s->len, length($hw));
}

if (10) {
	throws_ok { $stor->allocString() } qr/Usage: Cv::MemStorage::cvAllocString\(storage, ptr, len=-1\) at $0/;
}
