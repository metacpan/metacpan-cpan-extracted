
# This module is untested with anything older
require 5.008001;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Convert-Morse';

# Get most of the details from the primary module
all_from	'lib/Convert/Morse.pm';

requires	'perl'		=> 5.008001;
build_requires	'Test::More'	=> 0.47;

license		'gpl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Generate the Makefile
WriteAll;
