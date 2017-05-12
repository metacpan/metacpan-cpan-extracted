# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Attribute-Cached';
all_from        'lib/Attribute/Cached.pm';

license 'perl';
author 'osfameron';

# Specific dependencies
requires        'Attribute::Handlers' => '0.00';
build_requires  'Test::More'          => '0.42';

auto_install;
WriteAll;

