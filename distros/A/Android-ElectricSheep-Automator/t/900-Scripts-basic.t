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
 
my $FAILURE_REGEX = qr/\: error,/;
 
my %SCRIPTS = (
        # test the scripts (the keys) with the scripts contained in the values
        # as [script-to-get-success-output, script-to-get-failed-output]
        # script-filename
	'script/electric-sheep-close-app.pl' => ['--help'],
	'script/electric-sheep-dump-current-location.pl' => ['--help'],
	'script/electric-sheep-dump-current-screen-ui.pl' => ['--help'],
	'script/electric-sheep-dump-screen-shot.pl' => ['--help'],
	'script/electric-sheep-dump-screen-video.pl' => ['--help'],
	'script/electric-sheep-emulator-geofix.pl' => ['--help'],
	'script/electric-sheep-find-installed-apps.pl' => ['--help'],
	'script/electric-sheep-find-running-processes.pl' => ['--help'],
	'script/electric-sheep-install-app.pl' => ['--help'],
	'script/electric-sheep-open-app.pl' => ['--help'],
	'script/electric-sheep-pull-app-apk.pl' => ['--help'],
	'script/electric-sheep-viber-send-message.pl' => ['--help'],
);
 
#### nothing to change below
my $num_tests = 0;
 
my $dirname = File::Basename::dirname(__FILE__);
my $cmdline;
for my $ascriptname (sort keys %SCRIPTS){
	my $params = $SCRIPTS{$ascriptname};
        script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
        $cmdline = [$ascriptname, @$params];
        script_runs($cmdline, $ascriptname) or print "command failed: @$cmdline\n"; $num_tests++;
        script_stderr_unlike($FAILURE_REGEX, "stderr of output of script ($ascriptname) checked."); $num_tests++;
}
done_testing($num_tests);
