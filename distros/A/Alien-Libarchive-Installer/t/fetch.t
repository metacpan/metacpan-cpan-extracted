use strict;
use warnings;
use Alien::Libarchive::Installer;
use Test::More;

BEGIN {
  plan skip_all => "set ALIEN_LIBARCHIVE_INSTALLER_EXTRA_TESTS to run test"
    unless $ENV{TRAVIS_JOB_ID} || $ENV{ALIEN_LIBARCHIVE_INSTALLER_EXTRA_TESTS};
  plan skip_all => "test requires HTTP::Tiny"
    unless eval q{ use HTTP::Tiny; 1 };
}

plan tests => 2;

subtest 'specific version' => sub {
  plan tests => 2;
  my($location,$version) = eval { Alien::Libarchive::Installer->fetch(version => '3.1.1') };
  diag $@ if $@;
  ok -r $location, 'downloaded version 3.1.1';
  note $location;
  is $version, '3.1.1', "download version 3.1.1 is version 3.1.1";
};

subtest 'latest version' => sub {
  plan tests => 2;
  my($location,$version) = eval { Alien::Libarchive::Installer->fetch };
  diag $@ if $@;
  ok -r $location, 'downloaded latest';
  note $location;
  like $version, qr{^[1-9][0-9]*(\.[0-9]*){2}$}, "download version latest is $version";
};
