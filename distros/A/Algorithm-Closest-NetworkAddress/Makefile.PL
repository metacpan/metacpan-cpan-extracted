# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Algorithm-Closest-NetworkAddress';
all_from        'lib/Algorithm/Closest/NetworkAddress.pm';

# Specific dependencies
requires "Class::Struct";
build_requires  'Test::More'        => '0.42';

auto_install;
WriteAll;
