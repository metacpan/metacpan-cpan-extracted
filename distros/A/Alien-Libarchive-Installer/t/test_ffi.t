use strict;
use warnings;
use ExtUtils::CBuilder;
use Test::More;
use Alien::Libarchive::Installer;
use DynaLoader;

plan skip_all => 'test requires FFI::Raw'
  unless eval { require FFI::Raw };
plan skip_all => 'test requires dynamic libarchive'
  unless (defined DynaLoader::dl_findfile('-larchive')) || ($^O eq 'cygwin' && -e '/usr/bin/cygarchive-13.dll');

plan tests => 1;

my $installer = bless { cflags => [], libs => ['-larchive'] }, 'Alien::Libarchive::Installer';

my $version = $installer->test_ffi;
like $version, qr{^[1-9][0-9]*(\.[0-9]+){2}$}, "version = $version";
