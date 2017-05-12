#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Catalyst-Component-InstancePerContext';
abstract 'Moose role to create only one instance of component per context';
all_from 'lib/Catalyst/Component/InstancePerContext.pm';

# Specific dependencies
requires 'Catalyst';
requires 'Moose';
requires 'Scalar::Util';
build_requires 'Test::More';

auto_install;
WriteAll;
