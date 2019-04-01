#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

use Test::More;
use Test::Fatal;
use Test::File::Contents;
use File::Which;
use Path::Tiny;
use Log::Any::Test;
use Log::Any qw($log);

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
note("Temporary directory is $outdir");

my $to_compositions = new_ok(
	'Boxer::Task::Serialize' => [
		world   => $world,
		skeldir => path('share')->child('skel'),
		outdir  => $outdir,
		node    => 'parl-greens',
		format  => [qw{preseed script}],
	],
);
ok $to_compositions->run;
file_contents_like $outdir->child('preseed.cfg'),
	qr/\nd-i pkgsel\/include string acpi-support /,
	'preseed.cfg includes install of acpi-support';
file_contents_like $outdir->child('preseed.cfg'),
	qr/\nd-i pkgsel\/include string .*\n.* cups-/,
	'preseed.cfg includes avoidance of cups';
file_contents_like $outdir->child('preseed.cfg'),
	qr/\nd-i preseed\/late_command string .*\\\n suite=\S+\\\n chroot \/target apt-mark auto \\\n  acpi-support-base/,
	'preseed.cfg includes auto-marking of acpi-support-base';
file_contents_like $outdir->child('preseed.cfg'),
	qr{\n _setvar /target/etc/default/acpi-support },
	'preseed.cfg preserves "/target" prefix in paths';
file_contents_like $outdir->child('script.sh'),
	qr/\napt install acpi-support /,
	'script.sh includes install of acpi-support';
file_contents_like $outdir->child('script.sh'),
	qr/\napt install .*\n.* cups-/,
	'script.sh includes avoidance of cups';
file_contents_like $outdir->child('script.sh'),
	qr/\nsuite=\S+\n\napt-mark auto \\\n  acpi-support-base/,
	'script.sh includes auto-marking of acpi-support-base';
file_contents_like $outdir->child('script.sh'),
	qr{\n _setvar /etc/default/acpi-support },
	'script.sh strips "/target" prefix from paths';
$log->contains_ok( qr/^Resolving nodedir /, 'nodedir resolving logged' );
$log->contains_ok( qr/^Resolving nodedir /, 'nodedir resolving logged' );
$log->contains_ok( qr/^Classifying with reclass /, 'classification logged' );
$log->category_contains_ok(
	'Boxer::Task::Serialize',
	qr/^Serializing to preseed /, 'preseed logged'
);
$log->category_contains_ok(
	'Boxer::Task::Serialize',
	qr/^Serializing to script /, 'script logged'
);
$log->empty_ok("no more logs");

my $preseeddir = Path::Tiny->tempdir;
note("Temporary directory for preseed format is $preseeddir");
my $to_preseed = new_ok(
	'Boxer::Task::Serialize' => [
		world   => $world,
		skeldir => path('share')->child('skel'),
		outdir  => $preseeddir,
		node    => 'lxp5',
		format  => ['preseed'],
	],
);
ok $to_preseed->run;
ok -e $preseeddir->child('preseed.cfg'), 'preseed.cfg generated';
ok !-e $preseeddir->child('script.sh'),  'script.sh not generated';
$log->contains_ok( qr/^Serializing to preseed /, 'preseed logged' );
$log->does_not_contain_ok( qr/^Serializing to /, 'no more logged' );

my $scriptdir = Path::Tiny->tempdir;
note("Temporary directory for script format is $scriptdir");
my $to_script = new_ok(
	'Boxer::Task::Serialize' => [
		world   => $world,
		skeldir => path('share')->child('skel'),
		outdir  => $scriptdir,
		node    => 'lxp5',
		format  => ['script'],
	],
);
ok $to_script->run;
ok !-e $scriptdir->child('preseed.cfg'), 'preseed.cfg not generated';
ok -e $scriptdir->child('script.sh'),    'script.sh generated';
$log->contains_ok( qr/^Serializing to script /, 'script logged' );
$log->does_not_contain_ok( qr/^Serializing to /, 'no more logged' );

like exception {
	Boxer::Task::Serialize->new(
		world   => $world,
		skeldir => path('share')->child('skel'),
		outdir  => Path::Tiny->tempdir,
		node    => 'lxp5',
		format  => ['wrong'],
	);
}, qr/Must be one or more of these words:/,
	'Died as expected on wrong format';

is exception {
	Boxer::Task::Serialize->new(
		world   => $world,
		skeldir => path('share')->child('skel'),
		outdir  => Path::Tiny->tempdir,
		node    => 'lxp5',
		format  => [],
	);
}, undef, 'Died as expected on empty format';

done_testing();
