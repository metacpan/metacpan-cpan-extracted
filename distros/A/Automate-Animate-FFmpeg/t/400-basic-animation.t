#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use lib 'blib/lib';

use Test::More;
use Test2::Plugin::UTF8;

use File::Temp;
use Cwd;
use FindBin;
use File::Basename;

use Automate::Animate::FFmpeg;

our $VERSION = '0.12';

my $aaFF = Automate::Animate::FFmpeg->new();
ok(defined $aaFF, 'Automate::Animate::FFmpeg->new()'." : called and got defined result.") or BAIL_OUT;

my $exe; if( !defined($exe=$aaFF->ffmpeg_executable()) || ($exe=~/^\s*$/) || (! -x $exe) ){
	diag "There is no FFmpeg executable set in this module. No tests will be run.";
	done_testing;
	$File::Temp::KEEP_ALL = 0; File::Temp::cleanup();
	exit(0);
}


my $curdir = Cwd::abs_path($FindBin::Bin);
# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./shit
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # cleanup at the end
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

diag "temp dir: '$tmpdir' ...";
$File::Temp::KEEP_ALL = 0; File::Temp::cleanup();

# END
done_testing;
