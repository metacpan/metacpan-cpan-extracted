#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

use Module::Install::AuthorRequires 0.02;
use Module::Install::ReadmeFromPod 0.06;
use Module::Install::Repository 0.06;
use Module::Install::ExtraTests 0.006;

name          'DBIx-Class-MooseColumns';
all_from      'lib/DBIx/Class/MooseColumns.pm';
readme_from   'lib/DBIx/Class/MooseColumns.pm' => 'clean';
auto_set_repository;

requires 'Moose'                        => '1.19';
requires 'namespace::autoclean'         => '0.09';

test_requires 'Test::Most'              => '0.21';
test_requires 'Test::More'              => '0.92';
test_requires 'Test::Differences'       => '0.4801';
test_requires 'Test::Deep'              => '0.103';
test_requires 'Test::DBIx::Class'       => '0.10';
test_requires 'FindBin'                 => 0;
test_requires 'IO::All'                 => '0.41';
test_requires 'Path::Class'             => '0.16';
test_requires 'MooseX::NonMoose'        => '0.17';
test_requires 'Test::Aggregate'         => '0.363';

author_requires 'Test::Pod'             => '1.22';
author_requires 'Test::Pod::Coverage'   => '1.08';
author_requires 'Pod::Coverage'         => '0.18';
author_requires 'Test::Perl::Critic'    => '1.01';
author_requires 'Test::Benchmark'       => '0.004';
author_requires 'String::Random'        => '0.22';

extra_tests;

auto_install;

WriteAll;
