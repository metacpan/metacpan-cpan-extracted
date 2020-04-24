#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;
use Path::Tiny;
use App::Cmd::Tester::CaptureExternal;
use Log::Any::Test;
use Log::Any qw($log);

use Boxer::CLI;

use strictures 2;
no warnings "experimental::signatures";

my @base_cmd = qw(compose --datadir examples --skeldir share/skel);

subtest 'with "without options"' => sub {
	my $result = test_app( 'Boxer::CLI' => [ @base_cmd, qw( lxp5) ] );
	is $result->stdout, '',    'nothing sent to stdout';
	is $result->stderr, '',    'nothing sent to stderr';
	is $result->error,  undef, 'threw no exceptions';
	ok path('./preseed.cfg')->exists, 'preseed.cfg generated';
	ok path('./script.sh')->exists,   'script.sh generated';
	ok path('preseed.cfg')->remove,   'remove file preseed.cfg';
	ok path('script.sh')->remove,     'remove file script.sh';
	$log->contains_ok( qr/^Resolving classdir /, 'classdir logged' );
	$log->contains_ok( qr/^Resolving nodedir /,  'nodedir logged' );
	$log->contains_ok( qr/^Classifying /,        'classification logged' );
	$log->contains_ok( qr/^No tweaks resolved$/, 'lack of tweaks logged' );
	$log->contains_ok( qr/^Serializing to preseed /, 'preseed logged' );
	$log->contains_ok( qr/^Serializing to script /,  'script logged' );
	$log->empty_ok("no more logs");
};

subtest 'with "--format preseed"' => sub {
	my $result
		= test_app(
		'Boxer::CLI' => [ @base_cmd, qw(--format preseed lxp5) ] );
	is $result->stdout, '',    'nothing sent to stdout';
	is $result->stderr, '',    'nothing sent to stderr';
	is $result->error,  undef, 'threw no exceptions';
	ok path('preseed.cfg')->exists, 'preseed.cfg generated';
	ok !path('script.sh')->exists,  'script.sh not generated';
	ok path('preseed.cfg')->remove, 'remove file preseed.cfg';
	$log->contains_ok( qr/^Serializing to preseed /, 'preseed logged' );
	$log->does_not_contain_ok( qr/^Serializing to /, 'no more logged' );
};

subtest 'with "--format script"' => sub {
	my $result
		= test_app( 'Boxer::CLI' => [ @base_cmd, qw(--format script lxp5) ] );
	is $result->stdout, '',    'nothing sent to stdout';
	is $result->stderr, '',    'nothing sent to stderr';
	is $result->error,  undef, 'threw no exceptions';
	ok !path('preseed.cfg')->exists, 'preseed.cfg not generated';
	ok path('script.sh')->exists,    'script.sh generated';
	ok path('script.sh')->remove,    'remove file script.sh';
	$log->contains_ok( qr/^Serializing to script /, 'script logged' );
	$log->does_not_contain_ok( qr/^Serializing to /, 'no more logged' );
};

done_testing();
