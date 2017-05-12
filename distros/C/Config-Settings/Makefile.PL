use inc::Module::Install 0.68;

use strict;
use warnings;

name           'Config-Settings';
all_from       'lib/Config/Settings.pm';

requires       'Parse::RecDescent' => '1.95.1';

build_requires 'Test::More' => '0.47';
build_requires 'Test::Exception' => '0.21';
build_requires 'Test::Pod' => '1.26';

WriteAll;

