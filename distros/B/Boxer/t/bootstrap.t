#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;
use File::Which;
use App::Cmd::Tester::CaptureExternal;
use Log::Any::Test;
use Log::Any qw($log);

use Boxer::CLI;

use strictures 2;
no warnings "experimental::signatures";

plan skip_all => 'mmdebstrap executable required' unless which('mmdebstrap');

my @base_cmd = qw{bootstrap --datadir examples --skeldir share/skel --dryrun};

subtest 'without options' => sub {
	my $result = test_app( 'Boxer::CLI' => [ @base_cmd, qw(lxp5) ] );
	is $result->stdout, '',    'nothing sent to stdout';
	is $result->stderr, '',    'nothing sent to stderr';
	is $result->error,  undef, 'threw no exceptions';
	$log->contains_ok( qr/^Resolving classdir from /, 'classdir logged' );
	$log->contains_ok( qr/^Resolving nodedir from /,  'nodedir logged' );
	$log->contains_ok( qr/^Classifying /, 'classification logged' );
	$log->contains_ok( qr/^No tweaks /,   'lack of tweaks logged' );
	$log->category_contains_ok(
		'Boxer::Task::Bootstrap',
		qr/^Enabling apt mode needed by bootstrap helper mmdebstrap$/,
		'apt mode enabling logged'
	);
	$log->category_contains_ok(
		'Boxer::Task::Bootstrap',
		qr/^Bootstrap with mmdebstrap .*--include(?!.*--exclude).*bullseye[^,]+$/,
		'command logged'
	);
	$log->category_contains_ok(
		'Boxer::Task::Bootstrap',
		qr/^Skip execute command in dry-run mode$/,
		'skip command logged'
	);
	$log->empty_ok("no more logs");
};

subtest 'with "--helper debootstrap"' => sub {
	my $result = test_app(
		'Boxer::CLI' => [ @base_cmd, qw(--helper debootstrap lxp5) ] );
	is $result->stdout, '',    'nothing sent to stdout';
	is $result->stderr, '',    'nothing sent to stderr';
	is $result->error,  undef, 'threw no exceptions';
	$log->contains_ok( qr/^Resolving classdir /, 'classdir logged' );
	$log->contains_ok( qr/^Resolving nodedir /,  'nodedir logged' );
	$log->contains_ok( qr/^Classifying /,        'classification logged' );
	$log->contains_ok( qr/^No tweaks /,          'lack of tweaks logged' );
	$log->category_contains_ok(
		'Boxer::Task::Bootstrap',
		qr/^Bootstrap with debootstrap .*--exclude.*bullseye[^,]+$/,
		'command logged'
	);
	$log->category_contains_ok(
		'Boxer::Task::Bootstrap',
		qr/^Skip execute command in dry-run mode$/,
		'skip command logged'
	);
	$log->empty_ok("no more logs");
};

subtest 'with "-- foo bar"' => sub {
	my $result
		= test_app( 'Boxer::CLI' => [ @base_cmd, qw(lxp5 -- foo bar) ] );
	is $result->stdout, '',    'nothing sent to stdout';
	is $result->stderr, '',    'nothing sent to stderr';
	is $result->error,  undef, 'threw no exceptions';
	$log->contains_ok( qr/^Resolving classdir /, 'classdir logged' );
	$log->contains_ok( qr/^Resolving nodedir /,  'nodedir logged' );
	$log->contains_ok( qr/^Classifying /,        'classification logged' );
	$log->contains_ok( qr/^No tweaks /,          'lack of tweaks logged' );
	$log->category_contains_ok(
		'Boxer::Task::Bootstrap',
		qr/^Enabling apt mode needed by bootstrap helper mmdebstrap$/,
		'apt mode enabling logged'
	);
	$log->category_contains_ok(
		'Boxer::Task::Bootstrap',
		qr/^Bootstrap with mmdebstrap .*--include(?!.*--exclude).*bar[^,]+$/,
		'command logged'
	);
	$log->category_contains_ok(
		'Boxer::Task::Bootstrap',
		qr/^Skip execute command in dry-run mode$/,
		'skip command logged'
	);
	$log->empty_ok("no more logs");
};

done_testing();
