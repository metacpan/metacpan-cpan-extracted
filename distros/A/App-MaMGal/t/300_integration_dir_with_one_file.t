#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007-2010 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 21;
use Test::Exception;
use Test::Files;
use lib 'testlib';
use App::MaMGal::TestHelper;
use File::stat;
use Image::EXIF::DateTime::Parser;
use App::MaMGal::ImageInfoFactory;
use App::MaMGal::EntryFactory;

prepare_test_data;

my $time = time;
my $pic_time = $time - 120;
# touch up the directory and picture with different times
utime $time, $time, 'td/one_pic' or die "Touching directory failed";
utime $pic_time, $pic_time, 'td/one_pic/a1.png' or die "Touching picture failed";

use_ok('App::MaMGal::Entry::Dir');
my $d;
lives_ok(sub { $d = App::MaMGal::Entry::Dir->new(qw(td one_pic), stat('td/one_pic')) },   "dir can be created with an array: existant dir with one pic");
isa_ok($d, 'App::MaMGal::Entry::Dir');
my $mf = get_mock_formatter(qw(format stylesheet format_slide));
my $edtp = Image::EXIF::DateTime::Parser->new;
my $iif = App::MaMGal::ImageInfoFactory->new($edtp, get_mock_logger);
my $tools = {
	formatter => $mf,
	entry_factory => App::MaMGal::EntryFactory->new($mf, get_mock_mplayer_wrapper, $iif, get_mock_logger),
	image_info_factory => $iif,
};
$d->add_tools($tools);

my @ret = $d->elements;
is(scalar(@ret), 1,						"dir contains one element");
isa_ok($ret[0], 'App::MaMGal::Entry::Picture::Static');
is($ret[0]->element_index, 0,					"picture knows its index");
ok($d->is_interesting, 'dir with one picture is interesting');
is($d->tile_path, $ret[0]->tile_path, 'interesting thumbnail path of a dir with one picture is that pictures interesting thumbnail path');

my ($prev, $next);
dies_ok(sub { ($prev, $next) = $d->neighbours_of_index(1) },	"there is no index one");
lives_ok(sub { ($prev, $next) = $d->neighbours_of_index(0) },	"there is index zero");
ok(not(defined($prev)),						"there is no prev neighbour");
ok(not(defined($next)),						"there is no next neighbour");

dir_only_contains_ok('td/one_pic', [qw(a1.png)],                "Only the picture at start");

lives_ok(sub { $d->make },				"dir makes stuff and survives");

dir_only_contains_ok('td/one_pic', [qw(.mamgal-medium .mamgal-thumbnails .mamgal-slides index.html .mamgal-index.png
					a1.png
					.mamgal-thumbnails/a1.png
					.mamgal-medium/a1.png
					.mamgal-slides/a1.png.html)],
								"index, picture, .mamgal-thumbnails, .mamgal-medium and .mamgal-slides");

my $single_creation_time = $d->creation_time;
ok($single_creation_time, "There is some non-zero create time");
my @creation_time_range = $d->creation_time;
is(scalar @creation_time_range, 1, "Creation time range is empty");
is($creation_time_range[0], $single_creation_time, "Range-type creation time is equal to the scalar one");

my ($one_pic_entry) = $d->elements();
ok($one_pic_entry, "There is one picture");
my $picture_creation_time = $one_pic_entry->creation_time;
ok($picture_creation_time, "Picture has a creation time");
is($single_creation_time, $picture_creation_time, "The creation times match");

