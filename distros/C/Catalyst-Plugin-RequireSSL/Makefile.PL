#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

use Module::Install::ReadmeFromPod 0.06;
use Module::Install::AuthorRequires 0.02;
use Module::Install::Repository 0.06;
use Module::Install::ExtraTests 0.006;

name 'Catalyst-Plugin-RequireSSL';
all_from 'lib/Catalyst/Plugin/RequireSSL.pm';
readme_from 'lib/Catalyst/Plugin/RequireSSL.pm';
auto_set_repository;

requires 'Catalyst' => '5.23';
requires 'MRO::Compat';

test_requires 'Test::More';
test_requires 'Data::Dumper';
test_requires 'FindBin';
test_requires 'File::Spec';
test_requires 'Catalyst::Test';
test_requires 'HTTP::Request::Common';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::NoTabs' => '0.9';

extra_tests;

auto_install;

WriteAll;
