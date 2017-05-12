use strict;
use warnings;
use inc::Module::Install;

name('Cache-Adaptive');
author('Kazuho Oku <kazuhooku@gmail.com>');
abstract('A Cache Engine with Adaptive Lifetime Control');
version_from('lib/Cache/Adaptive.pm');
license('perl');

requires('Class::Accessor::Fast', 0.30);
requires('List::Util', 1.18);
requires('Time::HiRes', 1.65);

build_requires('Cache::MemoryCache');

use_test_base;

auto_include;
auto_install;

WriteAll;
