#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use lib 'blib/lib';

use Test::More;
use Test2::Plugin::UTF8;

use File::Temp;
use FindBin;
use Cwd::utf8 qw{abs_path};
use File::Basename;
use Unicode::Normalize;

use Automate::Animate::FFmpeg;

our $VERSION = '0.08';

my $curdir = abs_path($FindBin::Bin);

my $anim_outfile = 'abc';

# Now here is a problem: Some of these files/dirs
# with accented unicode characters in their name
# are presented differently on OSX than in Linux 
# and who knows what mess windows will be - still untested.
# So, a filename I typed here with say the greek iota-accented
# can fail to be found on the filesystem because the OS wrote
# it / or presents it with greek iota-not-accented followed by accent char
# a total whole mess!
# see https://perlmonks.org/?node_id=11156629
my @inpimages = map { Unicode::Normalize::NFD($_) } (
	File::Spec->catfile($curdir, 't-data', 'images', 'blue.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'green.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'red.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'κίτρινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'πράσινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'Κόκκινο.png'),
);
for (@inpimages){
	ok(-e $_, "test image '$_' exists on disk") or BAIL_OUT;
	ok(-f $_, "test image '$_' exists on disk and it is a file") or BAIL_OUT;
}

my $aaFF = Automate::Animate::FFmpeg->new({
	'input-images' => \@inpimages,
	'output-filename' => $anim_outfile,
});
ok(defined $aaFF, 'Automate::Animate::FFmpeg->new()'." : called and got defined result.") or BAIL_OUT;
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");

my $exe; if( !defined($exe=$aaFF->ffmpeg_executable()) || ($exe=~/^\s*$/) || (! -x $exe) ){
	diag "There is no FFmpeg executable set in this module. No tests will be run.";
	done_testing;
	$File::Temp::KEEP_ALL = 0; File::Temp::cleanup();
	exit(0);
}

$aaFF->frame_duration(3);
my $ret = $aaFF->_build_ffmpeg_cmdline();
ok(defined $ret, '_build_ffmpeg_cmdline()'." : called and got defined result.") or BAIL_OUT;
is(ref($ret), 'HASH', '_build_ffmpeg_cmdline()'." : called and got defined result which is a HASHref.");
for (qw/cmdline tmpfile/){
	ok(exists($ret->{$_}), '_build_ffmpeg_cmdline()'." : return contains key '$_'.");
}
ok(-f $ret->{'tmpfile'}, '_build_ffmpeg_cmdline()'." : created a tmpfile: '".$ret->{'tmpfile'}."'.");
ok(-s $ret->{'tmpfile'}, '_build_ffmpeg_cmdline()'." : created a tmpfile and it is not empty: '".$ret->{'tmpfile'}."'.");

unlink $ret->{'tmpfile'};

# END
done_testing;
