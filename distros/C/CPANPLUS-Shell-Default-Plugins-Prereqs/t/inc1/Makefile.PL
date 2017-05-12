# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'CSDPR_Test';
all_from        'lib/CSDPR_Test.pm';

# Specific dependencies
requires        'File::Spec'        => '0.80';
requires        'stuff'             => '0.80';
requires        'Hash::Util'        => 0;
build_requires  'Test::More'        => '0.42';

# auto_install;
WriteAll;
