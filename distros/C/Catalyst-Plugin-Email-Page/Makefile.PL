use strict;
use warnings;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Name of your distribution
name            'Catalyst-Plugin-Email-Page';

# Get most of the details from the primary module
# (The filename argument below is optional if it is placed
# consistently with the "name" above.)
all_from        'lib/Catalyst/Plugin/Email/Page.pm';

requires        'Readonly'           => 0;
requires        'Catalyst'           => '5.66';
requires        'Catalyst::Request'  => '0';
requires        'URI::Escape'        => '3.28';

build_requires  'Test::More'         => '0.62';
build_requires  'Test::Distribution' => '1.23';
    
# Auto-install all dependencies from CPAN
auto_install;
    
sign;

# Generate the Makefile
WriteAll;
