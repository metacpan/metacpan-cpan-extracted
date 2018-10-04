#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

#use Test::More tests => 6;
use Test::More;
use Test::Exception;
use Test::File::Contents;
use File::Which;
use Path::Tiny;

plan skip_all => 'reclass executable required' unless which('reclass');

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
	qr/\nd-i pkgsel\/include string acpi-support-base /,
	'preseed.cfg includes install of acpi-support-base';
file_contents_like $outdir->child('preseed.cfg'),
	qr/\nd-i pkgsel\/include string .*\n.* spamc-/,
	'preseed.cfg includes avoidance of spamc';
file_contents_like $outdir->child('preseed.cfg'),
	qr/\nd-i preseed\/late_command string .*\\\n suite=\S+\\\n chroot \/target apt-mark auto \\\n  ciderwebmail/,
	'preseed.cfg includes auto-marking of ciderwebmail';
file_contents_like $outdir->child('script.sh'),
	qr/\napt-get install acpi-support-base /,
	'script.sh includes install of acpi-support-base';
file_contents_like $outdir->child('script.sh'),
	qr/\napt-get install .*\n.* spamc-/,
	'script.sh includes avoidance of spamc';
file_contents_like $outdir->child('script.sh'),
	qr/\nsuite=\S+\n\napt-mark auto \\\n  ciderwebmail/,
	'script.sh includes auto-marking of ciderwebmail';

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
