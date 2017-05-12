#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007-2011 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 38;
use Test::Exception;
use Test::HTML::Content;
use Test::MockObject;
use lib 'testlib';
use App::MaMGal::TestHelper;

prepare_test_data;

use_ok('App::MaMGal::Formatter');
my $f;
dies_ok(sub { App::MaMGal::Formatter->new },     "formatter cannot be created without parameters");
dies_ok(sub { App::MaMGal::Formatter->new(1) },  "formatter cannot be created with some junk parameter");

my $le = get_mock_localeenv;
$le->mock('get_charset', sub { 'UTF-8' });
$le->mock('format_time', sub { $_[1] == 1227684276 ? '12:00:00' : '13:13:13' });
$le->mock('format_date', sub { $_[1] == 1227684276 ? '18 gru 2004' : '2 kwi 2004' });

lives_ok(sub { $f = App::MaMGal::Formatter->new($le) }, "formatter can be created with locale env");
isa_ok($f, 'App::MaMGal::Formatter');
lives_ok(sub { $f->set_locale_env($le) },          "Formatter accepts a set_locale_env call");

my $mock_td = Test::MockObject->new
	->mock('name', sub { 'td' })
	->mock('is_root', sub { 1 });
my $d = Test::MockObject->new
	->mock('elements', sub { () })
	->mock('containers', sub { $mock_td })
	->mock('name', sub { 'empty' })
	->mock('is_root', sub { 0 });
dies_ok(sub { $f->format },                             "dies with no args");
dies_ok(sub { $f->format(1) },                          "dies with non-dir arg");
dies_ok(sub { $f->format($d, 1) },                      "dies with more than one arg");
my $t;
lives_ok(sub { $t = $f->format($d) },                   "formatter survives dir page creation");
tag_ok($t, 'meta', { 'http-equiv' => "Content-Type", 'content' => "text/html; charset=UTF-8" }, "generated dir page contains charset declaration");
no_tag($t, "img", {},					"the resulting page has no pics");
tag_ok($t, "td", { _content => App::MaMGal::Formatter->EMPTY_PAGE_TEXT },
							"the resulting page has a cell");
link_ok($t, "../index.html",				"the resulting page has a link down");

# Elements with the same description, testing description suppression.
my $mock_td2 = Test::MockObject->new
	->mock('name', sub { 'td' })
	->mock('is_root', sub { 1 });
my $e1 = get_mock_entry(undef, description => 'description 1');
my $e2 = get_mock_entry(undef, description => 'description 2');
my $e3 = get_mock_entry(undef, description => 'description 2');
my $e4 = get_mock_entry(undef, description => 'description 1');
my $d2 = get_mock_entry('App::MaMGal::Entry::Dir', name => 'empty')
	->mock('elements', sub { ($e1, $e2, $e3, $e4) })
	->mock('containers', sub { $mock_td2 })
	->mock('is_root', sub { 0 });
my $t2;
lives_ok(sub { $t2 = $f->format($d2) },                 "formatter survives dir page creation");
tag_ok($t2, "img", {src=>'a/thumbnail/path'},		"the resulting page has some pics");
tag_count($t2, "span", { _content => 'description 1' }, 2,
							"the resulting page has description 1 twice");
tag_count($t2, "span", { _content => 'description 2' },	1,
							"the resulting page has description 2 once, the repeat is suppressed");
link_ok($t2, "../index.html",				"the resulting page has a link down");

my $mp = Test::MockObject->new;
$mp->set_isa('App::MaMGal::Picture::Static');
my $time = 1227684276;
$mp->mock('creation_time', sub { $time });
$mp->mock('page_path', sub { "pag'e_path" });
$mp->mock('thumbnail_path', sub { "tn'_pa?t#h" });
$mp->mock('description', sub { 'some description' });
$mp->mock('name', sub { 'foobar' });
my $cell;
lives_ok(sub { $cell = $f->entry_cell($mp) },		"formatter can format a cell");
ok($mp->called('creation_time'),			"formatter interrogated the entry for creation time");
ok($le->called('format_time'),				"formatter interrogated the locale env for time formatting");
ok($le->called('format_date'),				"formatter interrogated the locale env for date formatting");
tag_ok($cell, 'span', { 'class' => 'time', _content => '12:00:00' }, "generated cell contains creation time");
tag_ok($cell, 'span', { 'class' => 'date', _content => '18 gru 2004' }, "generated cell contains creation date");
tag_ok($cell, 'a', { href => "pag'e_path" }, "generated link is correctly encoded");
tag_ok($cell, 'img', { src => "tn'_pa%3Ft%23h" }, "generated img src is correctly encoded");

my $mp2 = Test::MockObject->new;
$mp2->set_isa('App::MaMGal::Picture::Static');
my ($time1, $time2) = (1080907993, 1227684276);
$mp2->mock('creation_time', sub { ($time1, $time2) });
$mp2->mock('page_path', sub { 'page_path ¿ó³w na staro¶æ wydziela wstrêtn± woñ' });
$mp2->mock('thumbnail_path', sub { 'tn_path ¿ó³w na staro¶æ wydziela wstrêtn± woñ' });
$mp2->mock('description', sub { 'some description ¿ó³w na staro¶æ wydziela wstrêtn± woñaae' });
$mp2->mock('name', sub { 'name ¿ó³w na staro¶æ wydziela wstrêtn± woñ' });
my $cell2;
lives_ok(sub { $cell2 = $f->entry_cell($mp2) },		"formatter can format a cell");
ok($mp2->called('creation_time'),			"formatter interrogated the entry for creation time");
ok($le->called('format_time'),				"formatter interrogated the locale env for time formatting");
ok($le->called('format_date'),				"formatter interrogated the locale env for date formatting");
tag_ok($cell2, 'span', { 'class' => 'time', _content => '12:00:00' }, "generated cell contains creation time");
tag_ok($cell2, 'span', { 'class' => 'date', _content => '18 gru 2004' }, "generated cell contains creation date");
tag_ok($cell2, 'span', { 'class' => 'time', _content => '13:13:13' }, "generated cell contains creation time");
tag_ok($cell2, 'span', { 'class' => 'date', _content => '2 kwi 2004' }, "generated cell contains creation date");
tag_ok($cell2, 'a', { href => 'page_path%20%BF%F3%B3w%20na%20staro%B6%E6%20wydziela%20wstr%EAtn%B1%20wo%F1' }, "generated link is correctly encoded");
tag_ok($cell2, 'img', { src => 'tn_path%20%BF%F3%B3w%20na%20staro%B6%E6%20wydziela%20wstr%EAtn%B1%20wo%F1' }, "generated image url is correctly encoded");
tag_ok($cell2, 'span', { class => 'desc', _content => qr'some description ¿ó³w na staro¶æ wydziela wstrêtn± woñaae' }, "generated description is not encoded");
