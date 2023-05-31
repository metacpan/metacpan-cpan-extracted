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

use utf8;

our $VERSION='0.16';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN,  ':encoding(UTF-8)';
# to avoid wide character in TAP output
# do this before loading Test* modules
use open ':std', ':encoding(utf8)';

use Test::More;
use Test::Script;
use File::Spec;
use File::Basename;

my %SCRIPTS = (
	# test the scripts (the keys) with the scripts contained in the values
	# as [script-to-get-success-output, script-to-get-failed-output]
	# script-filename          input-for-success    inout-for-failure
	'script/json2json.pl' => ['t-data/test.json' , 't-data/test.yaml'],
	'script/json2perl.pl' => ['t-data/test.json' , 't-data/test.yaml'],
	'script/json2yaml.pl' => ['t-data/test.json' , 't-data/test.yaml'],
	'script/perl2json.pl' => ['t-data/test.pl'   , 't-data/test.yaml'],
	'script/yaml2json.pl' => ['t-data/test.yaml' , 't-data/test.json'],
	'script/yaml2perl.pl' => ['t-data/test.yaml' , 't-data/test.json'],
);

#### nothing to change below
my $num_tests = 0;

my $dirname = File::Basename::dirname(__FILE__);

for my $ascriptname (sort keys %SCRIPTS){
	my $infile_SUCCESS = File::Spec->catfile($dirname, $SCRIPTS{$ascriptname}->[0]);
	ok(-f $infile_SUCCESS, "test file exists ($infile_SUCCESS)."); $num_tests++;
	ok(-s $infile_SUCCESS, "test file has content ($infile_SUCCESS)."); $num_tests++;
	script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
	script_runs([$ascriptname, '-i', $infile_SUCCESS], $ascriptname) or print "command failed: $ascriptname -i '$infile_SUCCESS'\n"; $num_tests++;
	script_stderr_unlike(qr/\: error,/, "stderr of output of script ($ascriptname) checked."); $num_tests++;

	my $infile_FAILURE = File::Spec->catfile($dirname, $SCRIPTS{$ascriptname}->[1]);
	ok(-f $infile_FAILURE, "test file exists ($infile_FAILURE)."); $num_tests++;
	ok(-s $infile_FAILURE, "test file has content ($infile_FAILURE)."); $num_tests++;
	# we have checked compilation already
	#script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
	script_fails([$ascriptname, '-i', $infile_FAILURE], {exit=>1}) or print "command succeeded when it should have failed: $ascriptname -i '$infile_FAILURE'\n"; $num_tests++;
	script_stderr_like(qr/\: error,/, "stderr of output of script ($ascriptname) should be indicating failure and contain the string ': error,'."); $num_tests++;

}
done_testing($num_tests);
