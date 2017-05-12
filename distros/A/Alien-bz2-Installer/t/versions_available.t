use strict;
use warnings;
use Alien::bz2::Installer;
use Test::More tests => 1;

is_deeply [Alien::bz2::Installer->versions_available], [$^O eq 'MSWin32' ? '1.0.5' : '1.0.6'], 'versions_available';
