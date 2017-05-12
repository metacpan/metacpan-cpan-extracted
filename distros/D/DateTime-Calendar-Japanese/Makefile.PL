use strict;
use inc::Module::Install;

name('DateTime-Calendar-Japanese');
all_from('lib/DateTime/Calendar/Japanese.pm');
requires('DateTime');
requires('DateTime::Util::Calc');
requires('DateTime::Calendar::Chinese');
requires('DateTime::Event::Sunrise');
requires('DateTime::Calendar::Japanese::Era');
requires('Params::Validate');

auto_install;
WriteAll;