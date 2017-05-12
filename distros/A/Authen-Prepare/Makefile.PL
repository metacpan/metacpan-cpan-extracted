use warnings;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Authen-Prepare';
all_from        'lib/Authen/Prepare.pm';

# Runtime dependencies
requires    'Carp'              => 0;
requires    'File::Spec'        => '0.80';
requires    'Readonly'          => 0;
requires    'Fcntl'             => 0;
requires    'IO::Prompt'        => 0;
requires    'Text::Glob'        => 0;

# Build dependencies
build_requires  'Test::More'        => '0.42';
build_requires  'Test::Exception'   => 0;
build_requires  'Test::Expect'      => 0;
build_requires  'Test::Warn'        => 0;

# Recommended dependencies

auto_install;
WriteAll;

# $Id$
