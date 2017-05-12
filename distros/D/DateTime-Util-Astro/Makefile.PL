#!perl
use strict;
use inc::Module::Install;

name('DateTime-Util-Astro');
all_from('lib/DateTime/Util/Astro.pm');
requires('Class::Data::Inheritable');
requires('DateTime');
requires('DateTime::Util::Calc' => '0.13');
requires('Math::BigInt');
requires('Math::Trig');
requires('POSIX');
build_requires("Test::More");

recommends('Cache::MemoryCache');

auto_install;
WriteAll;