#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use utf8;

use lib 'blib/lib';

use Test::More;
use Test2::Plugin::UTF8;
use Test::Script;
use Test::TempDir::Tiny;
use File::Spec;
use FindBin;
use Cwd;
use Encode;
use File::Basename;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Automate::Animate::FFmpeg;

our $VERSION = '0.13';

my $curdir = $FindBin::Bin;

my $aaFF = Automate::Animate::FFmpeg->new();
ok(defined $aaFF, 'Automate::Animate::FFmpeg->new()'." : called and got defined result.") or BAIL_OUT;
my $exe; if( !defined($exe=$aaFF->ffmpeg_executable()) || ($exe=~/^\s*$/) || (! -x $exe) ){
	diag "There is no FFmpeg executable set in this module. No tests will be run.";
	done_testing;
	exit(0);
}

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "output dir exists");

my $FAILURE_REGEX = qr/(?:\: error,)|(?:Usage)/;

my $FRAME_DURATION = 3;
my $VERBOSITY = 10;
my $outfile = File::Spec->catfile($tmpdir, "γαγαγαγ.mp4");
my @IMGS = (
	File::Spec->catfile($curdir, 't-data', 'images', 'blue.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'green.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'red.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'κίτρινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'πράσινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'Κόκκινο.png'),
);
my $input_images_file = File::Spec->catfile($tmpdir, "filelist.txt");
my $FH;
ok(open($FH, '>:encoding(UTF-8)', $input_images_file), "opened file '$input_images_file' for writing the file list.") or BAIL_OUT;
print $FH join("\n", @IMGS)."\n"; close $FH;

# script must be relative!
my $execu = File::Spec->catfile('script', 'automate-animate-ffmpeg.pl');

my @TESTS = (
	# test the scripts (the keys) with the scripts contained in the values
	# script-filename	  CLI-params-for-success    CLI-params-for-failure
	# input pattern to select exactly 4 images with shell glob
	[
		# will succeed
		[$execu, '--output-filename', $outfile, '--verbosity', $VERBOSITY, '--frame-duration', $FRAME_DURATION, '--input-pattern', '*.png', '.'],
		# will fail
		[$execu, '--output-filename', $outfile, '--verbosity', $VERBOSITY, '--frame-duration', $FRAME_DURATION, '--input-pattern', 'aa*.png', '.'],
	],
	# input pattern to select exactly 4 images with regex
	[
		# will succeed
		[$execu, '--output-filename', $outfile, '--verbosity', $VERBOSITY, '--frame-duration', $FRAME_DURATION, '--input-pattern', qw!regex(/.+?\.png/i)!, '.'],
		# will fail
		[$execu, '--output-filename', $outfile, '--verbosity', $VERBOSITY, '--frame-duration', $FRAME_DURATION, '--input-pattern', qw!regex(/.+?\.tiff/i)!, '.'],
	],
	# 4 input images using --input-image for each
	[
		# will succeed
		[$execu, '--output-filename', $outfile, '--verbosity', $VERBOSITY, '--frame-duration', $FRAME_DURATION, map { ('--input-image', $_) } @IMGS],
		# will fail
		[$execu, '--output-filename', $outfile, '--verbosity', $VERBOSITY, '--frame-duration', $FRAME_DURATION]
	],
	# file with input images paths: 4 images
	[
		# will succeed
		[$execu, '--output-filename', $outfile, '--verbosity', $VERBOSITY, '--frame-duration', $FRAME_DURATION, '--input-images-from-file', $input_images_file],
		# will fail
		undef
	],
);

#### nothing to change below
my $num_tests = 0;
 
my $dirname = File::Basename::dirname(__FILE__);
my $cmdline;
my $idx = 0;
for my $atest (@TESTS){
	$idx++;
	# must-succeed script:
	my $cmdline = $atest->[0];
	my $ascriptname = $cmdline->[0];
	my $atestname = 'test-'.$ascriptname.' no.'.${idx};
	script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
	script_runs($cmdline, $atestname) or print "command failed: @$cmdline\n"; $num_tests++;
	# did it find exactly 4 images?
	script_stdout_like('done, success. Output animation of 6 input images', $ascriptname);
	ok(-f $outfile, "script run and output file '$outfile' exists.");
	unlink($outfile);

	# optional must-fail script:
	$cmdline = $atest->[1];
	next unless defined $cmdline;
	script_stderr_unlike($FAILURE_REGEX, "stderr of output of script ($ascriptname) checked."); $num_tests++;
	# we have checked compilation already
	#script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
	script_fails($cmdline, {exit=>1}) or print "command succeeded when it should have failed: @$cmdline\n"; $num_tests++;
	script_stderr_like($FAILURE_REGEX, "stderr of output of script ($ascriptname) should be indicating failure and matching the regex $FAILURE_REGEX"); $num_tests++;
	unlink($outfile); # just in case
}

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();

