#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use lib 'blib/lib';

use Test::More;
use Test2::Plugin::UTF8;

use Cwd;
use FindBin;
use File::Basename;

use Automate::Animate::FFmpeg;

our $VERSION = '0.13';

my $curdir = Cwd::abs_path($FindBin::Bin);

my $anim_outfile = 'abc';

my @inpimages = (
	File::Spec->catfile($curdir, 't-data', 'images', 'red.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'green.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'blue.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'κίτρινο.png'),
);
my $aaFF = Automate::Animate::FFmpeg->new({
	'input-images' => \@inpimages,
	'output-filename' => $anim_outfile,
});
ok(defined $aaFF, 'Automate::Animate::FFmpeg->new()'." : called and got defined result.") or BAIL_OUT;

my $exe; if( !defined($exe=$aaFF->ffmpeg_executable()) || ($exe=~/^\s*$/) || (! -x $exe) ){
	diag "There is no FFmpeg executable set in this module. No tests will be run.";
	done_testing;
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
