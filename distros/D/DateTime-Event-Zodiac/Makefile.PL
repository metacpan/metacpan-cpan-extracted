# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install 1.05;

# Define metadata
name            'DateTime-Event-Zodiac';
all_from        'lib/DateTime/Event/Zodiac.pm';

perl_version    '5.006';

# Specific dependencies
requires        'DateTime'              => 0;
requires        'DateTime::Astro'       => 0;
requires        'Exporter'              => 0;

build_requires  'Test::More'            => 0;

WriteAll;

