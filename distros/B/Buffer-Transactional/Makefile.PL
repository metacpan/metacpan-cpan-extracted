#!/usr/bin/env perl
use inc::Module::Install;

name 'Buffer-Transactional';
all_from 'lib/Buffer/Transactional.pm';

requires 'Moose'            => '0.90';

requires 'IO::File'         => 0;
requires 'Data::UUID'       => 0;

# for testing
build_requires 'Test::More' => 0;
build_requires 'IO::Scalar' => 0;

WriteAll;
