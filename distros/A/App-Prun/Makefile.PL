#!/usr/bin/env perl

use lib '.';
use inc::Module::Install;

name     'App-Prun';
all_from 'lib/App/Prun.pm';
auto_set_repository;

no_index directory => '.hg';

requires 'File::Spec';
requires 'Getopt::Long';
requires 'Moo';
requires 'Parallel::ForkManager';
requires 'Storable';
requires 'namespace::clean';

recommends => 'Sys::CPU';

test_requires 'Test::More';
test_requires 'Test::Script' => '1.09';


install_script glob('script/*');
auto_install;
WriteAll;
