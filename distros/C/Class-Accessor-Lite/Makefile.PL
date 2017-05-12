use strict;
use inc::Module::Install;

name('Class-Accessor-Lite');
all_from('lib/Class/Accessor/Lite.pm');
readme_from('lib/Class/Accessor/Lite.pm');

repository('https://github.com/kazuho/p5-Class-Accessor-Lite');

auto_install;
WriteAll;
