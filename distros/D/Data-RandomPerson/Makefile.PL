use strict;
use warnings;

use 5.008007;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";

WriteMakefile (
  NAME             => 'Data::RandomPerson',
  ABSTRACT         => 'Create random person data',
  AUTHOR           => 'Michiel Beijen <michiel.beijen@gmail.com>',
  DISTNAME         => "Data-RandomPerson",
  VERSION_FROM     => 'lib/Data/RandomPerson.pm',
  LICENSE          => 'perl',
  MIN_PERL_VERSION => '5.008007',
  PREREQ_PM => {
    "Data::Random" => "0.12",
    "List::Util::WeightedChoice" => "0.06",
    "File::Share" => "0.06",
    "Module::Find" => 0,
  },
  TEST_REQUIRES => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88",
    "Time::Local" => "1.18",
  },
  test => {
    TESTS => "t/*.t"
  },
  CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::Share" => "0.06",
  },
  EXE_FILES => [],
  dist => {
    COMPRESS => "gzip -9f",
    SUFFIX => "gz",
  },
  META_MERGE => {
    resources => {
      repository => 'https://github.com/mbeijen/Data-RandomPerson',
      bugtracker => 'https://github.com/mbeijen/Data-RandomPerson/issues',
    },
    x_contributors => [
      'Michiel Beijen <michiel.beijen@gmail.com>',
    ],
  },
);


{
package
MY;
use File::ShareDir::Install qw(postamble);
}
