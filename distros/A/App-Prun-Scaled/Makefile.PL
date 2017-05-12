#!/usr/bin/env perl

use lib '.';
use inc::Module::Install;

name     'App-Prun-Scaled';
all_from 'lib/App/Prun/Scaled.pm';
auto_set_repository;

no_index directory => '.hg';

requires 'File::Spec';
requires 'Getopt::Long';
requires 'Moo';
requires 'Parallel::ForkManager::Scaled' => '0.13';
requires 'App::Prun';
requires 'Storable';
requires 'namespace::clean';

test_requires 'Test::More';
test_requires 'Test::Script' => '1.09';

install_script glob('script/*');
auto_install;
WriteAll;
