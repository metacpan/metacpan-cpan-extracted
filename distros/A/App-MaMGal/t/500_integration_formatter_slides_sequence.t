#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 11;
use Test::HTML::Content;
use lib 'testlib';
use App::MaMGal::TestHelper;
use Image::EXIF::DateTime::Parser;
use App::MaMGal::ImageInfoFactory;

prepare_test_data;

use App::MaMGal::Formatter;
use App::MaMGal::EntryFactory;
use App::MaMGal::LocaleEnv;
my $le = App::MaMGal::LocaleEnv->new(get_mock_logger);
$le->set_locale('C');
my $edtp = Image::EXIF::DateTime::Parser->new,
my $f = App::MaMGal::Formatter->new($le);
my $iif = App::MaMGal::ImageInfoFactory->new($edtp, get_mock_logger);
my $ef = App::MaMGal::EntryFactory->new($f, get_mock_mplayer_wrapper, $iif, get_mock_logger);
my $d = $ef->create_entry_for('td/more');

my @elems = $d->elements;
my $p = $elems[1];
my $t = $f->format_slide($p);
tag_ok($t, "img", {src => '../.mamgal-medium/b.png'}, "b.png: there is a medium pic on the page");
tag_ok($t, "a", {href => '../index.html'},           "b.png: there is a link to the index on the page");
tag_ok($t, "a", {href => 'a.png.html'},              "b.png: there is a link to previous slide");
tag_ok($t, "a", {href => 'x.png.html'},              "b.png: there is a link to next slide");
tag_ok($t, "a", {href => '../b.png'},                "b.png: there is a link to the image itself");
tag_count($t, "a", {}, 4,                            "b.png: there are only 3 links in total");
my $p2 = $elems[3];
my $t2 = $f->format_slide($p2);
tag_ok($t2, "img", {src => '../.mamgal-medium/x.png'}, "x.png: there is a medium pic on the page");
tag_ok($t2, "a", {href => '../index.html'},           "x.png: there is a link to the index on the page");
tag_ok($t2, "a", {href => 'b.png.html'},              "x.png: there is a link to previous slide");
tag_ok($t2, "a", {href => '../x.png'},                "x.png: there is a link to the image itself");
tag_count($t2, "a", {}, 3,                            "x.png: there are only 3 links in total");
