#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'DBIx-Class-InflateColumn-Path-Class';
abstract "Inflate columns into Path::Class objects";
all_from 'lib/DBIx/Class/InflateColumn/Path/Class.pm';

# Specific dependencies
requires 'DBIx::Class';
requires 'Path::Class';
build_requires 'Test::More';
build_requires 'SQL::Translator';

WriteAll;
