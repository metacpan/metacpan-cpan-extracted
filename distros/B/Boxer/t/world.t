#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

#use Test::More tests => 6;
use Test::More;
use Test::Exception;
use Test::File::Contents;
use Path::Tiny;

use_ok('Boxer::Part::Reclass');
use_ok('Boxer::World::Reclass');
use_ok('Boxer::Task::Classify');
use_ok('Boxer::Task::Serialize');

my $from_reclass = new_ok(
	'Boxer::Task::Classify' => [
		datadir => path('examples'),
	]
);

my $world  = $from_reclass->run;
my $outdir = Path::Tiny->tempdir;
note("Temporary output directory is $outdir");

my $to_compositions = new_ok(
	'Boxer::Task::Serialize' => [
		world   => $world,
		skeldir => path('share')->child('skel'),
		outdir  => $outdir,
		node    => 'lxp5',
	]
);
$to_compositions->run;
file_contents_like $outdir->child('preseed.cfg'),
	qr/pkgsel\/include string acpi-support/,
	'content of "preseed.cfg" seems ok';
file_contents_like $outdir->child('script.sh'),
	qr/apt-get install acpi-support/,
	'content of "script.sh" seems ok';

my $from_root = new_ok( 'Boxer::Task::Classify' => [ datadir => path('.') ] );

throws_ok(
	sub {
		$from_root->run;
	},
	qr/Must be an existing directory containing boxer classes/,
	'Died as expected on existing but wrong datadir'
);

throws_ok(
	sub {
		Boxer::Task::Classify->new( datadir => path('nowhere') );
	},
	qr/Directory 'nowhere' does not exist/,
	'Died as expected on non-exising datadir'
);

done_testing();
