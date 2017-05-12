use strict;
use warnings;
use ExtUtils::CBuilder;
use Test::More;
use Alien::bz2::Installer;

BEGIN {
  plan skip_all => 'test requires Devel::CheckLib'
    unless eval q{ use Devel::CheckLib; 1 };
}

plan skip_all => 'test requires bz2 already installed'
  unless check_lib( lib => 'bz2' );

plan tests => 1;

my $installer = bless { cflags => [], libs => ['-lbz2'] }, 'Alien::bz2::Installer';

my $version = $installer->test_compile_run;
ok $version, "version = $version";

