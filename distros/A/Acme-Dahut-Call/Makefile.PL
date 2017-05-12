# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Acme-Dahut-Call';
all_from 'lib/Acme/Dahut/Call.pm';

# Specific dependencies
requires 'Moose' => '0.20';
build_requires 'Test::More' => '0.42';

no_index 'directory' => 'demos';

auto_install;
WriteAll;
