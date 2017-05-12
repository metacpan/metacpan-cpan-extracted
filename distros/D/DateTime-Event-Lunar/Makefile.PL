use strict;
use inc::Module::Install;

name('DateTime-Event-Lunar');
all_from('lib/DateTime/Event/Lunar.pm');

requires 'DateTime';
requires 'DateTime::Set';
requires 'DateTime::Util::Astro' => 0.10;
requires 'Math::Round';

auto_install;
WriteAll;