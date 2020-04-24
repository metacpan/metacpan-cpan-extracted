#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep qw(:v1);
use Path::Tiny;
use Log::Any::Test;
use Log::Any qw($log);

use strictures 2;
no warnings "experimental::signatures";

use_ok('Boxer');

subtest 'list worlds' => sub {
	cmp_deeply [ Boxer->list_worlds ] => supersetof(
		'Boxer::World::Flat',
		'Boxer::World::Reclass',
		),
		'expected worlds available';
	$log->empty_ok("no more logs");
};

subtest 'get flat world' => sub {
	isa_ok Boxer->get_world('flat'), 'Boxer::World::Flat', 'expected class';
	$log->empty_ok("no more logs");
};

subtest 'get reclass world' => sub {
	isa_ok Boxer->get_world('reclass'), 'Boxer::World::Reclass',
		'expected class';
	$log->empty_ok("no more logs");
};

subtest 'get bogus world' => sub {
	is Boxer->get_world('foo'), undef, 'undefined as expected';
	$log->category_contains_ok(
		'Boxer',
		qr/^No world "foo" found$/, 'failure logged'
	);
	$log->empty_ok("no more logs");
};

subtest 'get empty world' => sub {
	isa_ok Boxer->get_world(), 'Boxer::World::Flat', 'expected class';
	$log->empty_ok("no more logs");
};

subtest 'get undefined world' => sub {
	isa_ok Boxer->get_world(), 'Boxer::World::Flat', 'expected class';
	$log->empty_ok("no more logs");
};

done_testing();
