#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'DBIx-Class-IntrospectableM2M';
abstract 'Introspect many-to-many relationships';
all_from 'lib/DBIx/Class/IntrospectableM2M.pm';

# Specific dependencie
requires 'DBIx::Class';
build_requires 'Test::More';

WriteAll;
