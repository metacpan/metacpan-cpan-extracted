#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'DBIx-Class-Schema-RestrictWithObject';
abstract 'Restrict ResultSets';
all_from 'lib/DBIx/Class/Schema/RestrictWithObject.pm';

# Specific dependencies
requires 'DBIx::Class' => 0.07000; ##just a safe number, no rhyme or reason

build_requires 'Test::More' => 0;

#ANYONE WANT TO GIVE ME VERSION NUMBERS??? PLEASE??
build_requires 'SQL::Translator' => 0;
build_requires 'Test::More' => 0;
build_requires 'Scalar::Util' => 0;
build_requires 'DBD::SQLite'  => 0;

auto_install;
WriteAll;
