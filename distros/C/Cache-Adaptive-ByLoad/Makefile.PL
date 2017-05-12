use strict;
use warnings;
use inc::Module::Install;

name('Cache-Adaptive-ByLoad');
author('Kazuho Oku <kazuhooku@gmail.com>');
abstract('A Cache Engine with Adaptive Lifetime Control by Load Average');
version_from('lib/Cache/Adaptive/ByLoad.pm');
license('perl');

requires('Cache::Adaptive', 0.03);
requires('Class::Accessor::Fast', 0.30);
requires('List::Util', 1.14);
requires('Time::HiRes', 1.65);

if ($^O eq 'linux') {
    requires('Sys::Statistics::Linux::LoadAVG');
} elsif ($^O =~ /.*bsd$|^darwin$/) {
    requires('BSD::getloadavg');
} else {
    die "$^O is not supported (only supports linux or freebsd)\n";
}

use_test_base;

auto_include;
auto_install;

WriteAll;
