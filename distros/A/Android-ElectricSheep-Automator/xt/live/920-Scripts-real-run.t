#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.09';
 
use Test::More;
use Test2::Plugin::UTF8;
use Test::Script;
use File::Spec;
use File::Basename;
use Test::TempDir::Tiny;

use Data::Roundtrip qw/perl2dump/;
 
my $FAILURE_REGEX = qr/\: error,/;
 
my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;
my $outdir = File::Spec->catdir($tmpdir, 'outapk');

my %SCRIPTS = (
        # test the scripts (the keys) with the parameters
	# we are happy they don't bomb
	'script/electric-sheep-close-app.pl' => ['--help'],
	'script/electric-sheep-dump-current-location.pl' => ['--help'],
	'script/electric-sheep-dump-current-screen-ui.pl' => ['--help'],
	'script/electric-sheep-dump-screen-shot.pl' => ['--help'],
	'script/electric-sheep-dump-screen-video.pl' => ['--help'],
	'script/electric-sheep-emulator-geofix.pl' => ['--help'],
	'script/electric-sheep-find-installed-apps.pl' => ['--help'],
	'script/electric-sheep-find-running-processes.pl' => ['--help'],
	'script/electric-sheep-install-app.pl' => ['--apk-filename', 't/t-data/apks/Gallery2.apk', '--configfile', 'config/myapp.conf', '-p', '-r', '-p', '-g'],
	'script/electric-sheep-open-app.pl' => ['--help'],
	'script/electric-sheep-pull-app-apk.pl' => ['--output', $tmpdir, '--configfile', 'config/myapp.conf', '--verbosity', $VERBOSITY, '--package', 'gallery', '--wildcard'],
	'script/electric-sheep-viber-send-message.pl' => ['--help'],
);
 
#### nothing to change below
 
my $dirname = File::Basename::dirname(__FILE__);
my $cmdline;
for my $ascriptname (sort keys %SCRIPTS){
	#next unless $ascriptname =~ /tric-sheep-pull/;
	my $params = $SCRIPTS{$ascriptname};
        script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n";
        $cmdline = [$ascriptname, @$params];
        script_runs($cmdline, $ascriptname) or print "command failed: @$cmdline\n";
        script_stderr_unlike($FAILURE_REGEX, "stderr of output of script ($ascriptname) checked.");
}

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

done_testing();

