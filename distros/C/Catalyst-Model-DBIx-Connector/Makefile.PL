#!/usr/bin/env perl

use inc::Module::Install;

name 'Catalyst-Model-DBIx-Connector';
all_from 'lib/Catalyst/Model/DBIx/Connector.pm';
license 'MIT';

requires 'namespace::autoclean';
requires 'Catalyst::Model';
requires 'DBIx::Connector';
requires 'Moose';

test_requires 'Test::More';

auto_install;
WriteAll;
