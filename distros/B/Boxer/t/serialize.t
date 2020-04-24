#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;
use Test::Fatal;
use Test::File::Contents;
use Path::Tiny;
use Log::Any::Test;
use Log::Any qw($log);

use strictures 2;
no warnings "experimental::signatures";

use_ok('Boxer::Part::Reclass');
use_ok('Boxer::World::Reclass');
use_ok('Boxer::Task::Classify');
use_ok('Boxer::Task::Serialize');

my $classifier = new_ok(
	'Boxer::Task::Classify' => [
		datadir => path('examples'),
	]
);

my $world = $classifier->run;

subtest 'in preseed and script formats' => sub {
	my $outdir = Path::Tiny->tempdir;
	note("Temporary output directory is $outdir");

	my $serializer = new_ok(
		'Boxer::Task::Serialize' => [
			world   => $world,
			skeldir => path('share')->child('skel'),
			outdir  => $outdir,
			node    => 'parl-greens',
			format  => [qw{preseed script}],
		],
	);
	ok $serializer->run;
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
	$log->contains_ok( qr/^Resolving classdir /, 'classdir logged' );
	$log->contains_ok( qr/^Resolving nodedir /,  'nodedir logged' );
	$log->contains_ok( qr/^Classifying /,        'classification logged' );
	$log->category_contains_ok(
		'Boxer::Task::Serialize',
		qr/^Serializing to preseed /, 'preseed logged'
	);
	$log->category_contains_ok(
		'Boxer::Task::Serialize',
		qr/^Serializing to script /, 'script logged'
	);
	$log->empty_ok("no more logs");
};

subtest 'in preseed format' => sub {
	my $outdir = Path::Tiny->tempdir;
	note("Temporary output directory is $outdir");

	my $serializer = new_ok(
		'Boxer::Task::Serialize' => [
			world   => $world,
			skeldir => path('share')->child('skel'),
			outdir  => $outdir,
			node    => 'lxp5',
			format  => ['preseed'],
		],
	);
	ok $serializer->run;
	ok -e $outdir->child('preseed.cfg'), 'preseed.cfg generated';
	ok !-e $outdir->child('script.sh'),  'script.sh not generated';
	$log->contains_ok( qr/^Serializing to preseed /, 'preseed logged' );
	$log->does_not_contain_ok( qr/^Serializing to /, 'no more logged' );
};

subtest 'in script format' => sub {
	my $outdir = Path::Tiny->tempdir;
	note("Temporary output directory is $outdir");

	my $serializer = new_ok(
		'Boxer::Task::Serialize' => [
			world   => $world,
			skeldir => path('share')->child('skel'),
			outdir  => $outdir,
			node    => 'lxp5',
			format  => ['script'],
		],
	);
	ok $serializer->run;
	ok !-e $outdir->child('preseed.cfg'), 'preseed.cfg not generated';
	ok -e $outdir->child('script.sh'),    'script.sh generated';
	$log->contains_ok( qr/^Serializing to script /, 'script logged' );
	$log->does_not_contain_ok( qr/^Serializing to /, 'no more logged' );
};

subtest 'in wrong format' => sub {
	like exception {
		Boxer::Task::Serialize->new(
			world   => $world,
			skeldir => path('share')->child('skel'),
			outdir  => Path::Tiny->tempdir,
			node    => 'lxp5',
			format  => ['wrong'],
		);
	}, qr/Must be one or more of these words:/, 'Died as expected';
};

subtest 'in empty format' => sub {
	is exception {
		Boxer::Task::Serialize->new(
			world   => $world,
			skeldir => path('share')->child('skel'),
			outdir  => Path::Tiny->tempdir,
			node    => 'lxp5',
			format  => [],
		);
	}, undef, 'Died as expected';
};

done_testing();
