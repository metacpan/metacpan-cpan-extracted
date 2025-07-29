#!perl
# taint mode off because Test::Script does not like it and it fails
# because of
# Insecure dependency in open while running with -T switch at /usr/local/share/perl5/Test/Script.pm line 137.
# The module per se can be run under taint mode, there is no problem there.
# It's just that testing whether a script (of those in the script/ dir)
# compiles or run using Test::Script causes the above error.
#-T
use 5.008;
use strict;
use warnings;
 
our $VERSION='0.30';
 
use Test::More;
use Test2::Plugin::UTF8;
use Test::Script;
use File::Spec;
use File::Basename;
 
my $FAILURE_REGEX = qr/\: error,/;
 
my %SCRIPTS = (
        # test the scripts (the keys) with the scripts contained in the values
        # as [script-to-get-success-output, script-to-get-failed-output]
        # script-filename          input-for-success    inout-for-failure
        'script/json2json.pl' => ['t-data/succeeding/test.json' , 't-data/failing/test.yaml'],
        'script/json2perl.pl' => ['t-data/succeeding/test.json' , 't-data/failing/test.yaml'],
        'script/json2yaml.pl' => ['t-data/succeeding/test.json' , 't-data/failing/test.yaml'],
        'script/perl2json.pl' => ['t-data/succeeding/test.pl'   , 't-data/failing/test.yaml'],
        'script/yaml2json.pl' => ['t-data/succeeding/test.yaml' , 't-data/failing/test.json'],
        'script/yaml2perl.pl' => ['t-data/succeeding/test.yaml' , 't-data/failing/test.json'],
);
 
#### nothing to change below
my $num_tests = 0;
 
my $dirname = File::Basename::dirname(__FILE__);
my $cmdline;
for my $ascriptname (sort keys %SCRIPTS){
        my $infile_SUCCESS = File::Spec->catfile($dirname, $SCRIPTS{$ascriptname}->[0]);
        ok(-f $infile_SUCCESS, "test file exists ($infile_SUCCESS)."); $num_tests++;
        ok(-s $infile_SUCCESS, "test file has content ($infile_SUCCESS)."); $num_tests++;
        script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
        $cmdline = [$ascriptname, '-i', $infile_SUCCESS];
        script_runs($cmdline, $ascriptname) or print "command failed: @$cmdline\n"; $num_tests++;
        script_stderr_unlike($FAILURE_REGEX, "stderr of output of script ($ascriptname) checked."); $num_tests++;
 
        my $infile_FAILURE = File::Spec->catfile($dirname, $SCRIPTS{$ascriptname}->[1]);
        ok(-f $infile_FAILURE, "test file exists ($infile_FAILURE)."); $num_tests++;
        ok(-s $infile_FAILURE, "test file has content ($infile_FAILURE)."); $num_tests++;
        # we have checked compilation already
        #script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
        $cmdline = [$ascriptname, '-i', $infile_FAILURE];
        script_fails($cmdline, {exit=>1}) or print "command succeeded when it should have failed: @$cmdline\n"; $num_tests++;
        script_stderr_like($FAILURE_REGEX, "stderr of output of script ($ascriptname) should be indicating failure and matching the regex $FAILURE_REGEX"); $num_tests++;
}
done_testing($num_tests);
