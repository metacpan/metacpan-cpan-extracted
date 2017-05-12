#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 87;
use Test::Exception;
use Test::Files;
use lib 'testlib';
use App::MaMGal::TestHelper;

prepare_test_data;

use_ok('App::MaMGal::EntryFactory');
my $ef;
dies_ok(sub { App::MaMGal::EntryFactory->new },                               "EF cannot be instantiated without arguments");
my ($mf, $mw, $mif, $ml) = (get_mock_formatter, get_mock_mplayer_wrapper, get_mock_iif, get_mock_logger);

sub tools_ok {
	my $e = shift;
	my $level = $Test::Builder::Level;
	local $Test::Builder::Level = $level + 1;
	is($e->tools->{entry_factory}, $ef,                              "entry factory in tools is correct");
	is($e->tools->{formatter}, $mf,                                  'formatter in tools is correct');
	is($e->tools->{mplayer_wrapper}, $mw,                            'mplayer wrapper in tools is correct');
	is($e->tools->{image_info_factory}, $mif,                        'image info factory in tools is correct');
	is($e->tools->{logger}, $ml,                                     'logger in tools is correct');
}

dies_ok(sub { App::MaMGal::EntryFactory->new($mf, $mw) },                     "EF cannot be instantiated with just formatter, wrapper");
dies_ok(sub { App::MaMGal::EntryFactory->new($mf, $mw, $mif) },               "EF cannot be instantiated with just formatter, wrapper and image info factory");
lives_ok(sub { $ef = App::MaMGal::EntryFactory->new($mf, $mw, $mif, $ml) },   "EF can be instantiated with formatter, wrapper, parser, image info factory and logger");
my $e;
lives_ok(sub { $e = $ef->create_entry_for('td/empty_file') },            "EF creates entry from empty file");
isa_ok($e, 'App::MaMGal::Entry::NonPicture',                                  "expected entry is a NonPicture");
is($e->name, 'empty_file',                                               "file name matches");
tools_ok($e);

lives_ok(sub { $e = $ef->create_entry_for('td/symlink_to_empty_file') }, "EF creates entry from symlink to empty file");
isa_ok($e, 'App::MaMGal::Entry::NonPicture',                                  "expected entry is a NonPicture");
is($e->name, 'symlink_to_empty_file',                                    "file name matches");
tools_ok($e);

lives_ok(sub { $e = $ef->create_entry_for('td/empty') },                 "EF creates entry from empty dir");
isa_ok($e, 'App::MaMGal::Entry::Dir',                                         "expected entry is a Dir");
is($e->name, 'empty',                                                    "file name matches");
tools_ok($e);

lives_ok(sub { $e = $ef->create_entry_for('td/symlink_to_empty') },      "EF creates entry from symlink to empty dir");
isa_ok($e, 'App::MaMGal::Entry::Dir',                                         "expected entry is a Dir");
is($e->name, 'symlink_to_empty',                                         "file name matches");
tools_ok($e);

lives_ok(sub { $e = $ef->create_entry_for('td/symlink_broken') },        "EF creates entry from broken symlink");
isa_ok($e, 'App::MaMGal::Entry::BrokenSymlink',                               "expected entry is a BrokenSymlink");
is($e->name, 'symlink_broken',                                           "file name matches");
tools_ok($e);

lives_ok(sub { $e = $ef->create_entry_for('td/one_pic/a1.png') },        "EF creates entry from a picture");
isa_ok($e, 'App::MaMGal::Entry::Picture::Static',                             "expected entry is a Picture::Static");
is($e->name, 'a1.png',                                                   "file name matches");
tools_ok($e);

lives_ok(sub { $e = $ef->create_entry_for('td/symlink_pic.png') },       "EF creates entry from a symlink to picture");
isa_ok($e, 'App::MaMGal::Entry::Picture::Static',                             "expected entry is a Picture::Static");
is($e->name, 'symlink_pic.png',                                          "file name matches");
tools_ok($e);

lives_ok(sub { $e = $ef->create_entry_for('td/symlink_pic_noext') },     "EF creates entry from a secret symlink to picture");
isa_ok($e, 'App::MaMGal::Entry::NonPicture',                                  "expected entry is a NonPicture");
is($e->name, 'symlink_pic_noext',                                        "file name matches");
tools_ok($e);

dies_ok(sub { $ef->create_entry_for('td/non-existant') },                "EF dies on nonexistant arg");

# some corner cases:
my $rootdir;
lives_ok(sub { $rootdir = $ef->create_entry_for('/') },            "EF creates entry for '/'");
isa_ok($rootdir, 'App::MaMGal::Entry::Dir',                             "entry created by EF for '/' is a dir");
ok($rootdir->is_root,                                              "dir root created by EF knows that it's root");
is($rootdir->name, '/',                                            "dir root created by EF knows its name");
tools_ok($rootdir);

my $cwd;
lives_ok(sub { $cwd = $ef->create_entry_for('.') },                "EF creates entry for '.'");
isa_ok($cwd, 'App::MaMGal::Entry::Dir',                                 "entry created by EF for CWD is a dir");
isnt($cwd->name, '.',                                              "entry created by EF for CWD knows its canonical name (and not '.')");
tools_ok($cwd);

