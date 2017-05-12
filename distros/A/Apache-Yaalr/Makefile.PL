use 5.008008;

use inc::Module::Install;

# Meta Data 
name 'Apache-Yaalr';
all_from 'lib/Apache/Yaalr.pm'; # finds $VERSION

# Dependencies
requires 'Carp' => 0;           # using 1.04
requires 'Template' => 0;       # using 2.14

# other 
abstract_from 'lib/Apache/Yaalr.pm';
author 'Jeremiah Foster <jeremiah@jeremiahfoster.com>';

auto_install;
WriteAll;
