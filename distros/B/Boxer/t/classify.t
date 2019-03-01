#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

use Test::More;
use Test::Fatal;
use File::Which;
use Path::Tiny;

plan skip_all => 'reclass executable required' unless which('reclass');

use_ok('Boxer::Task::Classify');

my $from_reclass = new_ok(
	'Boxer::Task::Classify' => [
		datadir => path('examples'),
	]
);

my $from_root = new_ok( 'Boxer::Task::Classify' => [ datadir => path('.') ] );

like exception {
	$from_root->run;
}, qr/Must be an existing directory containing boxer classes/,
	'Died as expected on existing but wrong datadir';

like exception {
	Boxer::Task::Classify->new( datadir => path('nowhere') );
}, qr/Directory 'nowhere' does not exist/,
	'Died as expected on non-exising datadir';

done_testing();
