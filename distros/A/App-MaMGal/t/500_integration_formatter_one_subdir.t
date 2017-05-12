#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 10;
use Test::HTML::Content;
use lib 'testlib';
use App::MaMGal::TestHelper;

prepare_test_data;

use App::MaMGal::LocaleEnv;
my $le = App::MaMGal::LocaleEnv->new(get_mock_logger);
$le->set_locale('C');
use App::MaMGal::Formatter;
my $f = App::MaMGal::Formatter->new($le);

use App::MaMGal::EntryFactory;
use App::MaMGal::ImageInfoFactory;
my $d = App::MaMGal::EntryFactory->new($f, get_mock_mplayer_wrapper, App::MaMGal::ImageInfoFactory->new(get_mock_datetime_parser, get_mock_logger), get_mock_logger)->create_entry_for('td/one_dir');
$d->set_root(1);
my $t = $f->format($d);
text_ok($t, 'one_dir',					"there is the directory name");
tag_count($t, "a", { href => 'subdir/index.html' }, 2,	"there are two links to the subdir");
tag_ok($t, "img", { src => 'subdir/.mamgal-index.png' },	"there is a pic on the page");
no_tag($t, "a", { href => "../index.html" },		"there is no link down");
no_text($t, '/',					"there is no (leading) slash on root dir page");

my $tsub = $f->format(($d->elements)[0]);
no_tag($tsub, "img", {},				"subdir index has no pics");
link_ok($tsub, "../index.html",				"subdir has link down");
text_ok($tsub, 'subdir',				"there is the directory name");
text_ok($tsub, 'one_dir',				"there is the parent directory name");
no_text($tsub, 'td',					"there isn't the grandfather directory name");
