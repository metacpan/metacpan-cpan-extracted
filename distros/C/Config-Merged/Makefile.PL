use strict;
use warnings;

use inc::Module::Install;

name 'Config-Merged';
all_from 'lib/Config/Merged.pm';

requires 'Config::Any' => '0.00';

test_requires 'Test::Deep' => '0.00';
test_requires 'Test::More' => '0.00';

auto_install;
WriteAll;
