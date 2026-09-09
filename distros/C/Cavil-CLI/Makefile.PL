# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Cavil::CLI',
  VERSION_FROM     => 'lib/Cavil/CLI.pm',
  ABSTRACT_FROM    => 'lib/Cavil/CLI.pm',
  AUTHOR           => 'Sebastian Riedel <sriedel@suse.com>',
  LICENSE          => 'gpl_2',
  MIN_PERL_VERSION => '5.020',

  EXE_FILES => ['script/cavil-cli'],

  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '7.12'},
  PREREQ_PM          => {
    'Mojolicious'     => '9.34',
    'IO::Socket::SSL' => '2.009'
  },
  TEST_REQUIRES => {'Test::More' => '0.98'},

  META_MERGE => {
    'meta-spec'    => {version => 2},
    dynamic_config => 0,
    resources      => {
      repository => {
        type => 'git',
        url  => 'https://github.com/openSUSE/cavil-cli.git',
        web  => 'https://github.com/openSUSE/cavil-cli'
      },
      bugtracker => {web => 'https://github.com/openSUSE/cavil-cli/issues'},
      license    => ['https://www.gnu.org/licenses/old-licenses/gpl-2.0.html'],
    },
  },

  clean => {FILES => 'cover_db'},
  test  => {TESTS => 't/*.t'}
);
