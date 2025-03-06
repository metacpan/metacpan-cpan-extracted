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
use Test::TempDir::Tiny;
use Cwd;
use FindBin;
use File::Basename;

use Automate::Animate::FFmpeg;

our $VERSION = '0.13';

my $aaFF = Automate::Animate::FFmpeg->new();
ok(defined $aaFF, 'Automate::Animate::FFmpeg->new()'." : called and got defined result.") or BAIL_OUT;

my $exe; if( !defined($exe=$aaFF->ffmpeg_executable()) || ($exe=~/^\s*$/) || (! -x $exe) ){
	diag "There is no FFmpeg executable set in this module. No tests will be run.";
	done_testing;
	exit(0);
}


my $curdir = Cwd::abs_path($FindBin::Bin);

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "output dir exists");

my $anim_outfile = File::Spec->catfile($tmpdir, 'out.mp4');

my @inpimages = (
	File::Spec->catfile($curdir, 't-data', 'images', 'red.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'green.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'blue.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'κίτρινο.png'),
);

$aaFF->input_images(\@inpimages);
$aaFF->output_filename($anim_outfile);
$aaFF->frame_duration(3);
is($aaFF->make_animation(), 1, "make_animation() : run and got good result back");
ok(-f $anim_outfile, "$anim_outfile created") or BAIL_OUT("no output was created, something seriously wrong.");

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing;
