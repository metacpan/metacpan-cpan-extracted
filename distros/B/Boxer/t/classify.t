#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

use Test::More;
use Test::Fatal;
use File::Which;
use Path::Tiny;
use Log::Any::Test;
use Log::Any qw($log);

plan skip_all => 'reclass executable required' unless which('reclass');

use_ok('Boxer::Task::Classify');

my $from_reclass = new_ok(
	'Boxer::Task::Classify' => [
		datadir => path('examples'),
	]
);
$log->empty_ok("no more logs");

my $from_root = new_ok( 'Boxer::Task::Classify' => [ datadir => path('.') ] );
$log->empty_ok("no more logs");

like exception {
	$from_root->run;
}, qr/Must be an existing directory containing boxer classes/,
	'Died as expected on existing but wrong datadir';
$log->category_contains_ok(
	'Boxer::Task::Classify',
	qr/^Resolving nodedir from datadir/, 'datadir resolving logged'
);
$log->empty_ok("no more logs");

like exception {
	Boxer::Task::Classify->new( datadir => path('nowhere') );
}, qr/Directory 'nowhere' does not exist/,
	'Died as expected on non-exising datadir';
$log->empty_ok("no more logs");

done_testing();
