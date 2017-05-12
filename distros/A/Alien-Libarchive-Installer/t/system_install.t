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

plan tests => 2;

my $type = eval { require FFI::Raw } ? 'both' : 'compile';

note "type = $type";

my $installer = Alien::Libarchive::Installer->system_install( test => $type );
isa_ok $installer, 'Alien::Libarchive::Installer';
like $installer->version, qr{^[1-9][0-9]*(\.[0-9]+){2}$}, "version = " . $installer->version;
