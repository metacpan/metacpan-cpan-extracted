use strict;
use warnings;
use Alien::bz2::Installer;
use Test::More;

plan skip_all => 'set ALIEN_BZ2_INSTALLER_EXTRA_TESTS to run test'
  unless $ENV{TRAVIS_JOB_ID} || $ENV{ALIEN_BZ2_INSTALLER_EXTRA_TESTS};
plan skip_all => 'test requires HTTP::Tiny'
  unless eval q{ use HTTP::Tiny; 1 };

plan tests => 1;

subtest 'latest version' => sub {
  plan tests => 2;
  my($location, $version) = eval { Alien::bz2::Installer->fetch };
  diag $@ if $@;
  ok -r $location, 'downloaded latest';
  like $version, qr{^[1-9][0-9]*(\.[0-9]*){2}$}, "download version latest is $version";
};
