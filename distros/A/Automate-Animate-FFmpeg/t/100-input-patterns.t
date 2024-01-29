#!/usr/bin/env perl

# NOTE: unicode filenames may not be canonicalised
# e.g. iota-including-accent and iota with separate accent.
# the OS will not care but if you do comparisons you will fail
# So, consider canonicalising the filenames if you are doing comparison
# e.g. in the tests
# see https://perlmonks.org/?node_id=11156629 -- thanks Corion

use strict;
use warnings;

use utf8;

use lib 'blib/lib';

use Test::More;
use Test2::Plugin::UTF8;

use File::Temp;
use Cwd::utf8 qw{abs_path};
use FindBin;
use File::Basename;
use Encode;
use Unicode::Normalize;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Automate::Animate::FFmpeg;

our $VERSION = '0.08';

my $curdir = abs_path($FindBin::Bin);

my $anim_outfile = 'abc';
my $VERBOSITY = 10;
my $adir;

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
	File::Spec->catfile($curdir, 't-data', 'images', 'κίτρινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'red.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'green.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'πράσινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'Κόκκινο.png'),
);
for (@inpimages){
	ok(-e $_, "test image '$_' exists on disk") or BAIL_OUT;
	ok(-f $_, "test image '$_' exists on disk and it is a file") or BAIL_OUT;
}

my $aaFF = Automate::Animate::FFmpeg->new({
	'verbosity' => $VERBOSITY
});
ok(defined $aaFF, 'Automate::Animate::FFmpeg->new()'." : called and got defined result.") or BAIL_OUT;

is($aaFF->input_pattern(['*.png']), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } @inpimages },
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

$adir = File::Spec->catdir($curdir, 't-data');
ok(-d $adir, "input dir '$adir' exists") or BAIL_OUT;
is($aaFF->input_pattern(['*.png', $adir]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } @inpimages },
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

$adir = File::Spec->catdir($curdir, 't-data');
ok(-d $adir, "input dir '$adir' exists") or BAIL_OUT;
is($aaFF->input_pattern([qw!regex(/.+?\.PNG$/i)!, $adir]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } @inpimages },
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

# let's check if the jpg file is picked, we are importing 1more file
$adir = File::Spec->catdir($curdir, 't-data');
ok(-d $adir, "input dir '$adir' exists") or BAIL_OUT;
is($aaFF->input_patterns([
  [qw!regex(/.+?\.PNG$/i)!, $adir],
  [qw!regex(/.+?\.JPG$/i)!, $adir],
]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), 2+scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } (@inpimages,
			    Unicode::Normalize::NFD(File::Spec->catfile($curdir, 't-data', 'images', 'green.jpg')),
			    Unicode::Normalize::NFD(File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'πράσινο.jpg'))
			  )
	},
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

# now try searching in a unicode dir
@inpimages = map { Unicode::Normalize::NFD($_) } (
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'πράσινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'Κόκκινο.png'),
);
for (@inpimages){
	ok(-e $_, "test image '$_' exists on disk") or BAIL_OUT;
	ok(-f $_, "test image '$_' exists on disk and it is a file") or BAIL_OUT;
}

$adir = File::Spec->catdir($curdir, 't-data', 'images', 'Περισσότερα');
ok(-d $adir, "input dir '$adir' exists") or BAIL_OUT;
is($aaFF->input_pattern(['*.png', $adir]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } @inpimages },
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

$adir = File::Spec->catdir($curdir, 't-data', 'images', 'Περισσότερα');
ok(-d $adir, "input dir '$adir' exists") or BAIL_OUT;
is($aaFF->input_pattern([qw!regex(/.+?\.PNG$/i)!, $adir]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } @inpimages },
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

$adir = File::Spec->catdir($curdir, 't-data', 'images', 'Περισσότερα');
ok(-d $adir, "input dir '$adir' exists") or BAIL_OUT;
is($aaFF->input_patterns([
  [qw!regex(/.+?\.PNG$/i)!, $adir],
  [qw!regex(/.+?\.JPG$/i)!, $adir],
]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), 1+scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } (@inpimages,
			    Unicode::Normalize::NFD(File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'πράσινο.jpg'))
			  )
	},
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

# now chdir to the unicode dir
$adir = File::Spec->catdir($curdir, 't-data', 'images', 'Περισσότερα');
ok(-d $adir, "input dir '$adir' exists") or BAIL_OUT;
chdir $adir;

@inpimages = map { Unicode::Normalize::NFD($_) } (
	File::Spec->catfile($adir, 'πράσινο.png'),
	File::Spec->catfile($adir, 'Κόκκινο.png'),
);
for (@inpimages){
	ok(-e $_, "test image '$_' exists on disk") or BAIL_OUT;
	ok(-f $_, "test image '$_' exists on disk and it is a file") or BAIL_OUT;
}

is($aaFF->input_pattern(['*.png']), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } @inpimages },
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

is($aaFF->input_pattern([qw!regex(/.+?\.PNG$/i)!, $adir]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } @inpimages },
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

is($aaFF->input_patterns([
  [qw!regex(/.+?\.PNG$/i)!],
  [qw!regex(/.+?\.JPG$/i)!],
]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), 1+scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } (@inpimages,
			    Unicode::Normalize::NFD(File::Spec->catfile($adir, 'πράσινο.jpg'))
			  )
	},
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

is($aaFF->input_patterns([
  [qw!regex(/.+?\.PNG$/i)!, $adir],
  [qw!regex(/.+?\.JPG$/i)!, $adir],
]), 1, 'input_pattern()'." : called and got good result.");
is(scalar(@{ $aaFF->input_images() }), 1+scalar(@inpimages), "exactly ".scalar(@inpimages)." were imported for the animation.") or BAIL_OUT("no only ".scalar(@{ $aaFF->input_images() })." were imported -- probably unicode/normalisation problems.");
is_deeply(
	{ map { Unicode::Normalize::NFD($_) => 1 } @{ $aaFF->input_images() } },
	{ map { $_ => 1 } (@inpimages,
			    Unicode::Normalize::NFD(File::Spec->catfile($adir, 'πράσινο.jpg'))
			  )
	},
	'input_pattern()'." : called and got the images expected."
) or BAIL_OUT(perl2dump($aaFF->input_images())."above is what I got and below is what I expected (order is not important):\n".perl2dump(\@inpimages));
$aaFF->clear_input_images();

# END
done_testing;
