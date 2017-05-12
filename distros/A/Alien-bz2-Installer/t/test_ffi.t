use strict;
use warnings;
use ExtUtils::CBuilder;
use Test::More;
use Alien::bz2::Installer;
use DynaLoader;

plan skip_all => 'test requires FFI::Raw'
  unless eval { require FFI::Raw };
plan skip_all => 'test requires dynamic bz2'
  unless defined DynaLoader::dl_findfile('-lbz2')
  &&     DynaLoader::dl_findfile('-lbz2') !~ /\.a$/;

plan tests => 1;

my $installer = bless { clfags => [], libs => ['-lbz2'] }, 'Alien::bz2::Installer';

my $version = $installer->test_ffi;
ok $version, "version = $version";
