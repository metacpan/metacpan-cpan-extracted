#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

requires 'parent' => '0.224';
requires 'Moo' => '1.004006';
requires 'MooX::HandlesVia' => '0.001005';
requires 'Scalar::Util' => '1.35';
requires 'Type::Tiny' => '0.042';
requires 'DateTimeX::Easy' => '0.089';
requires 'List::MoreUtils' => '0.30';
requires 'Module::Pluggable' => '3.9';

test_requires 'DBIx::Class' => '0.08127';
test_requires 'DateTime::Format::SQLite' => '0.11'; ## needed by DBIC for datetime in/deflators
test_requires 'SQL::Translator' => '0.11020';
test_requires 'Test::More' => '0.98';
test_requires 'File::Find';
test_requires 'YAML::Tiny' => '1.48';
test_requires 'Path::Class' => '0.23';

all_from 'lib/DBIx/Class/Schema/PopulateMore.pm';
require 'maint/Makefile.PL.include'
  if $Module::Install::AUTHOR;

WriteAll;

