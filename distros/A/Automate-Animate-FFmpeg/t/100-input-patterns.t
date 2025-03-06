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
use Encode;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Automate::Animate::FFmpeg;

our $VERSION = '0.13';

my $curdir = Cwd::abs_path($FindBin::Bin);

my $anim_outfile = 'abc';
my $VERBOSITY = 10;

my @inpimages = (
	File::Spec->catfile($curdir, 't-data', 'images', 'blue.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'κίτρινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'red.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'green.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'πράσινο.png'),
	File::Spec->catfile($curdir, 't-data', 'images', 'Περισσότερα', 'Κόκκινο.png'),
);
my $aaFF = Automate::Animate::FFmpeg->new({
	'verbosity' => $VERBOSITY
});
ok(defined $aaFF, 'Automate::Animate::FFmpeg->new()'." : called and got defined result.") or BAIL_OUT;

is($aaFF->input_pattern(['*.png']), 1, 'input_pattern()'." : called and got good result.");
my $s1 = { map { $_ => 1 } @{ $aaFF->input_images() } };
my $s2 = { map { $_ => 1 } @inpimages };
is_deeply($s1, $s2, 'input_pattern()'." : called and got the images expected.") or BAIL_OUT("got:\n".perl2dump($s1)."\nexpected:\n".perl2dump($s2)."see above");
$aaFF->clear_input_images();

is($aaFF->input_pattern(['*.png', File::Spec->catdir($curdir, 't-data')]), 1, 'input_pattern()'." : called and got good result.");
$s1 = { map { $_ => 1 } @{ $aaFF->input_images() } };
$s2 = { map { $_ => 1 } @inpimages };
is_deeply($s1, $s2, 'input_pattern()'." : called and got the images expected.") or BAIL_OUT("got:\n".perl2dump($s1)."\nexpected:\n".perl2dump($s2)."see above");
$aaFF->clear_input_images();

is($aaFF->input_pattern([qw!regex(/.+?\.PNG$/i)!, File::Spec->catdir($curdir, 't-data')]), 1, 'input_pattern()'." : called and got good result.");
$s1 = { map { $_ => 1 } @{ $aaFF->input_images() } };
$s2 = { map { $_ => 1 } @inpimages };
is_deeply($s1, $s2, 'input_pattern()'." : called and got the images expected.") or BAIL_OUT("got:\n".perl2dump($s1)."\nexpected:\n".perl2dump($s2)."see above");
$aaFF->clear_input_images();

is($aaFF->input_patterns([
  [qw!regex(/.+?\.PNG$/i)!, File::Spec->catdir($curdir, 't-data')],
  [qw!regex(/.+?\.JPG$/i)!, File::Spec->catdir($curdir, 't-data')],
]), 1, 'input_pattern()'." : called and got good result.");
$s1 = { map { $_ => 1 } @{ $aaFF->input_images() } };
$s2 = { map { $_ => 1 } (@inpimages,File::Spec->catfile($curdir, 't-data', 'images', 'green.jpg')) };
is_deeply($s1, $s2, 'input_pattern()'." : called and got the images expected.") or BAIL_OUT("got:\n".perl2dump($s1)."\nexpected:\n".perl2dump($s2)."see above");
# the above fails in some Windows when filenames contain unicode
# not bothering
$aaFF->clear_input_images();

# END
done_testing;
