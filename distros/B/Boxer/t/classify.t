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

use_ok('Boxer::Task::Classify');

subtest 'from examples' => sub {
	my $classifier = new_ok(
		'Boxer::Task::Classify' => [ datadir => path('examples'), ] );
	$log->empty_ok("no more logs");

	my $world = $classifier->run;
	isa_ok $world, 'Boxer::World',
		'classified world is a Boxer::World';
	$log->category_contains_ok(
		'Boxer::Task::Classify',
		qr/^Resolving nodedir /, 'datadir logged'
	);
	$log->category_contains_ok(
		'Boxer::Task::Classify',
		qr/^Resolving classdir /, 'classdir logged'
	);
	$log->category_contains_ok(
		'Boxer::Task::Classify',
		qr/^Classifying /, 'classification logged'
	);
	$log->empty_ok("no more logs");
};

subtest 'from empty dirs' => sub {
	my $dir = Path::Tiny->tempdir;
	note("Temporary directory is $dir");

	my $classifier = new_ok( 'Boxer::Task::Classify' => [ datadir => $dir ] );
	$log->empty_ok("no more logs");

	like exception {
		$classifier->run;
	}, qr/Must be an existing directory /, 'Died as expected';
	$log->category_contains_ok(
		'Boxer::Task::Classify',
		qr/^Resolving classdir from /, 'classdir logged'
	);
	$log->empty_ok("no more logs");
};

subtest 'from non-existing dirs' => sub {
	my $dir = Path::Tiny->tempdir;
	note("Temporary directory is $dir");

	like exception {
		Boxer::Task::Classify->new( datadir => $dir->child('foo') );
	}, qr/Directory '\S+' does not exist/, 'Died as expected';
	$log->empty_ok("no more logs");
};

done_testing();
