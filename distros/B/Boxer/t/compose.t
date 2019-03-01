#!/usr/bin/perl

use v5.14;
use utf8;
use strictures 2;

use Test::More;
use File::Which;
use Path::Tiny;
use App::Cmd::Tester::CaptureExternal;

use Boxer::CLI;

plan skip_all => 'reclass executable required' unless which('reclass');

my @base_cmd = qw(compose --datadir examples --skeldir share/skel);

my $result = test_app( 'Boxer::CLI' => [ @base_cmd, qw( lxp5) ] );
is $result->stdout, '',                     'printed what we expected';
is $result->stderr, "No tweaks resolved\n", 'no-tweaks warning sent to sderr';
is $result->error,  undef,                  'threw no exceptions';
ok path('./preseed.cfg')->exists, 'preseed.cfg generated';
ok path('./script.sh')->exists,   'script.sh generated';
ok path('preseed.cfg')->remove,   'remove file preseed.cfg';
ok path('script.sh')->remove,     'remove file script.sh';

my $preseed
	= test_app( 'Boxer::CLI' => [ @base_cmd, qw(--format preseed lxp5) ] );
is $preseed->stdout, '', 'printed what we expected';
is $preseed->stderr, "No tweaks resolved\n",
	'no-tweaks warning sent to sderr';
is $preseed->error, undef, 'threw no exceptions';
ok path('preseed.cfg')->exists, 'preseed.cfg generated';
ok !path('script.sh')->exists,  'script.sh not generated';
ok path('preseed.cfg')->remove, 'remove file preseed.cfg';

my $script
	= test_app( 'Boxer::CLI' => [ @base_cmd, qw(--format script lxp5) ] );
is $script->stdout, '',                     'printed what we expected';
is $script->stderr, "No tweaks resolved\n", 'no-tweaks warning sent to sderr';
is $script->error,  undef,                  'threw no exceptions';
ok !path('preseed.cfg')->exists, 'preseed.cfg not generated';
ok path('script.sh')->exists,    'script.sh generated';
ok path('script.sh')->remove,    'remove file script.sh';

done_testing();
