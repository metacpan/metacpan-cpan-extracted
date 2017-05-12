#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 40;
use Test::HTML::Content;
use Test::Exception;
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
my $f = App::MaMGal::Formatter->new($le);
my $edtp = Image::EXIF::DateTime::Parser->new;
my $iif = App::MaMGal::ImageInfoFactory->new($edtp, get_mock_logger);
my $ef = App::MaMGal::EntryFactory->new($f, get_mock_mplayer_wrapper, $iif, get_mock_logger);

#
# a dir with a single pic _without_ description
#

my $time = 1228933448;
utime($time, $time, 'td/more/zzz another subdir/p.png') == 1 or die "Failed to touch file";
my $dir_nd = $ef->create_entry_for('td/more/zzz another subdir');

# this is p.png, which has no description
my $p_nd = ($dir_nd->elements)[0];
my $t_nd;
lives_ok(sub { $t_nd = $f->format($dir_nd) },       "formatter formats index page with one picture");
tag_ok($t_nd, "a", { href => '.mamgal-slides/p.png.html' }, "there is a link to the slide");
tag_ok($t_nd, "img", { src => '.mamgal-thumbnails/p.png' }, "there is a pic on the page");
text_ok($t_nd, 'p.png',                             "does not contain filename alone");

dies_ok(sub { $f->format_slide },                    "dies with no arg");
dies_ok(sub { $f->format_slide(1) },                 "dies non pic arg");
dies_ok(sub { $f->format_slide($p_nd, 2) },          "dies with > 1 arg");
my $st_p_nd;
lives_ok(sub { $st_p_nd = $f->format_slide($p_nd) }, "lives with a pic arg");

text_ok($st_p_nd, 'p.png',                           "slide contains filename");
for my $n ('td', 'more', 'zzz another subdir') {
	text_ok($st_p_nd, $n,                        "slide contains parent filename");
}
tag_ok($st_p_nd, "img", {src => '../.mamgal-medium/p.png'},  "there is a medium pic on the page");
no_tag($st_p_nd, "embed",                            "there is no embed tag on the page");
tag_count($st_p_nd, "img", {}, 1,                    "just one img tag");
tag_ok($st_p_nd, "a", {href => '../index.html'},     "there is a link up on the page");
tag_ok($st_p_nd, "a", {href => '../p.png'},          "there is a link to image itself");
tag_count($st_p_nd, "a", {}, 2,                      "two links in total");
tag_ok($st_p_nd, "span", {class => 'date', _content => '03/18/08'},"there is a date");
tag_ok($st_p_nd, "span", {class => 'time', _content => '09:33:32'},"there is a time");

my $ct_p_nd;
lives_ok(sub { $ct_p_nd = $f->entry_cell($p_nd) },   "lives through cell entry generation");
text_ok($ct_p_nd, 'p.png',                           "cell contains filename");

#
# a dir with a single pic _with_ description
#

my $d = $ef->create_entry_for('td/one_pic');
my $t;
lives_ok(sub { $t = $f->format($d) },             "formatter formats index page with one picture");
tag_ok($t, "a", { href => '.mamgal-slides/a1.png.html' }, "there is a link to the slide");
tag_ok($t, "img", { src => '.mamgal-thumbnails/a1.png' }, "there is a pic on the page");
text_ok($t, 'Another test image.',                 "contains description");
no_text($t, 'a1.png',                              "does not contain filename alone");

my $p = $ef->create_entry_for('td/one_pic/a1.png');

my $st;
lives_ok(sub { $st = $f->format_slide($p) },      "formatter formats a slide");
tag_ok($st, "img", {src => '../.mamgal-medium/a1.png'},   "there is a medium pic on the page");
tag_count($st, "img", {}, 1,                      "just one img tag");
tag_ok($st, "a", {href => '../index.html'},       "there is a link up on the page");
tag_ok($st, "a", {href => '../a1.png'},           "there is a link to image itself");
tag_count($st, "a", {}, 2,                        "two links");
text_ok($st, 'Another test image.',               "contains description");
no_text($st, 'a1.png',                            "does not contain filename alone");

my $ct;
lives_ok(sub { $ct = $f->entry_cell($p) },        "lives through cell entry generation");
no_text($ct, 'a1.png',                            "cell does not contain filename");
text_ok($ct, 'Another test image.',               "cell contains description");

my $p_dir = ($d->elements)[0];
my $st2;
lives_ok(sub { $st2 = $f->format_slide($p_dir) }, "formatter formats a slide");
is($st, $st2,                                     "slide is the same for both kinds of picture access");

