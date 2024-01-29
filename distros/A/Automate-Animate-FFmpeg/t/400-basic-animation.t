#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use lib 'blib/lib';

use Test::More;
use Test2::Plugin::UTF8;

use File::Temp;
use Cwd::utf8 qw{abs_path};
use FindBin;
use Unicode::Normalize;
use File::Basename;

use Automate::Animate::FFmpeg;

our $VERSION = '0.08';

my $aaFF = Automate::Animate::FFmpeg->new();
ok(defined $aaFF, 'Automate::Animate::FFmpeg->new()'." : called and got defined result.") or BAIL_OUT;

my $exe; if( !defined($exe=$aaFF->ffmpeg_executable()) || ($exe=~/^\s*$/) || (! -x $exe) ){
	diag "There is no FFmpeg executable set in this module. No tests will be run.";
	done_testing;
	$File::Temp::KEEP_ALL = 0; File::Temp::cleanup();
	exit(0);
}

my $curdir = abs_path($FindBin::Bin);
# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./shit
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # cleanup at the end
ok(-d $tmpdir, "output dir exists");

my $anim_outfile = File::Spec->catfile($tmpdir, 'out.mp4');

# Now here is a problem: Some of these files/dirs
# with accented unicode characters in their name
# are presented differently on OSX than in Linux 
# and who knows what mess windows will be - still untested.
# So, a filename I typed here with say the greek iota-accented
# can fail to be found on the filesystem because the OS wrote
# it / or presents it with greek iota-not-accented followed by accent char
# a total whole mess!
# see https://perlmonks.org/?node_id=11156629
my @inpimages = map { Unicode::Normalize::NFD($_) } reverse (
	File::Spec->catfile($curdir, 't-data', 'images', 'red.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'green.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'blue.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'κίτρινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'πράσινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'Κόκκινο.png'),
);
for (@inpimages){
	ok(-e $_, "test image '$_' exists on disk") or BAIL_OUT;
	ok(-f $_, "test image '$_' exists on disk and it is a file") or BAIL_OUT;
}

$aaFF->input_images(\@inpimages);
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
$aaFF->output_filename($anim_outfile);
$aaFF->frame_duration(3);
is($aaFF->make_animation(), 1, "make_animation() : run and got good result back");
ok(-f $anim_outfile, "$anim_outfile created") or BAIL_OUT("no output was created, something seriously wrong.");

diag "temp dir: '$tmpdir' ...";
$File::Temp::KEEP_ALL = 0; File::Temp::cleanup();

# END
done_testing;
