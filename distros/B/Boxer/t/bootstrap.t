#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

use Test::More;
use File::Which;
use App::Cmd::Tester::CaptureExternal;

use Boxer::CLI;

plan skip_all => 'reclass executable required' unless which('reclass');
plan skip_all => 'reclass executable required' unless which('mmdebstrap');

my $result;
my @base_cmd = qw{bootstrap --datadir examples --skeldir share/skel --dryrun};

$result = test_app( 'Boxer::CLI' => [ @base_cmd, qw(lxp5) ] );
like $result->stdout,
	qr/^mmdebstrap --include [a-z]\S+,[a-z]\S+- buster\n$/,
	'printed what we expected';
is $result->stderr, "No tweaks resolved\n", 'nothing sent to sderr';
is $result->error, undef, 'threw no exceptions';

$result = test_app(
	'Boxer::CLI' => [ @base_cmd, qw(--helper debootstrap lxp5) ] );
like $result->stdout,
	qr/^debootstrap --include [a-z]\S+ --exclude [a-z]\S+ buster\n$/,
	'printed what we expected';
is $result->stderr, "No tweaks resolved\n", 'nothing sent to sderr';
is $result->error, undef, 'threw no exceptions';

$result = test_app( 'Boxer::CLI' => [ @base_cmd, qw(lxp5 -- foo bar) ] );
like $result->stdout,
	qr/^mmdebstrap --include [a-z]\S+,[a-z]\S+- buster foo bar\n$/,
	'printed what we expected';
is $result->stderr, "No tweaks resolved\n", 'nothing sent to sderr';
is $result->error, undef, 'threw no exceptions';

done_testing();
