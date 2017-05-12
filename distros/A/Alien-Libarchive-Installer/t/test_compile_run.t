use strict;
use warnings;
use ExtUtils::CBuilder;
use Test::More;
use Alien::Libarchive::Installer;

BEGIN {
  plan skip_all => 'test  requires Devel::CheckLib'
    unless eval q{ use Devel::CheckLib; 1};
}

plan skip_all => 'requires libarchive already installed'
  unless check_lib( lib => 'archive', header => 'archive.h' );

plan tests => 1;

my $installer = bless { cflags => [], libs => ['-larchive'] }, 'Alien::Libarchive::Installer';

my $version = $installer->test_compile_run;
like $version, qr{^[1-9][0-9]*(\.[0-9]+){2}$}, "version = $version";
