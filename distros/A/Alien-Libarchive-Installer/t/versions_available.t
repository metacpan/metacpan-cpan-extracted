use strict;
use warnings;
use Test::More;
use Alien::Libarchive::Installer;

plan skip_all => "set ALIEN_LIBARCHIVE_INSTALLER_EXTRA_TESTS to run test"
  unless $ENV{TRAVIS_JOB_ID} || $ENV{ALIEN_LIBARCHIVE_INSTALLER_EXTRA_TESTS};
plan skip_all => 'test requires HTTP::Tiny'
  unless eval { require HTTP::Tiny };

plan tests => 1;

my @versions = eval { Alien::Libarchive::Installer->versions_available };
diag $@ if $@;
ok @versions > 0, 'some versions';
note $_ for @versions;
