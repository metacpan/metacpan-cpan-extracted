#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 15;
use Test::Exception;
use lib 'testlib';
use App::MaMGal::TestHelper;

prepare_test_data;

use_ok('App::MaMGal::LocaleEnv');

# test parameter checks
dies_ok(sub { App::MaMGal::LocaleEnv->new },               "Locale env dies on creation with no args");
dies_ok(sub { App::MaMGal::LocaleEnv->new(1) },            "Locale env dies on creation with junk arg");
my $le;
lives_ok(sub { $le = App::MaMGal::LocaleEnv->new(get_mock_logger) }, "new succeeds with logger");
my $ch;
lives_ok(sub { $ch = $le->get_charset },             "Locale env returns a charset");
ok($ch,                                              "The charset returned by get_charset is never empty");

# It is not possible to portably test whether changing, retrieving or setting
# anything other than C locale is possible, because the set of available
# locales is system-specific.
lives_ok(sub { $le->set_locale("C") },               "Locale env can set a posix locale");
lives_ok(sub { $ch = $le->get_charset },             "Locale env can retrieve the charset name afterwards");
# The following string should be returned whether nl_langinfo is available or not
is($ch, "ANSI_X3.4-1968",                            "Charset name retrieved by locale env is expected name for posix locale");

# Time formatting
my ($t, $d);
lives_ok(sub { $t = $le->format_time(1227723614) },  "Locale env can format time");
lives_ok(sub { $d = $le->format_date(1227723614) },  "Locale env can format date");
# cannot test exact date and time, as it will differ depending on the timezone
like($t, qr'\d{2}:\d{2}:14',                         "Time is correct");
like($d, qr'11/2[567]/08',                           "Date is correct");
is($le->format_time(), '??:??:??',                   "Locale env can format unknown time");
is($le->format_date(), '???',                        "Locale env can format unknown date");
