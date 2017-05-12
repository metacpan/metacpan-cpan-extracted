use strict;
use warnings;
use Test::More tests => 1;
use Alien::Libarchive::Installer;

is ref(Alien::Libarchive::Installer->build_requires), 'HASH', 'build_requires';
