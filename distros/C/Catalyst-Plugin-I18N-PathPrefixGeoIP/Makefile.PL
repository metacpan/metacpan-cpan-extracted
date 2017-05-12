#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

use Module::Install::AuthorRequires 0.02;
use Module::Install::ReadmeFromPod 0.06;
use Module::Install::Repository 0.06;
use Module::Install::ExtraTests 0.006;
use Module::Install::Share 0.91;

name 'Catalyst-Plugin-I18N-PathPrefixGeoIP';
all_from 'lib/Catalyst/Plugin/I18N/PathPrefixGeoIP.pm';
readme_from 'lib/Catalyst/Plugin/I18N/PathPrefixGeoIP.pm' => 'clean';
auto_set_repository;

requires 'Catalyst'                   => '5.80013';
requires 'Catalyst::Plugin::I18N'     => '0.09';
requires 'I18N::LangTags::List'       => '0.35';
requires 'Moose'                      => '0.92';
requires 'namespace::autoclean'       => '0.09';
requires 'List::Util'                 => 0;
requires 'Scope::Guard'               => '0.03';
requires 'Geo::IP'	                  => 0;


test_requires 'Test::Most'            => '0.21';
test_requires 'Test::More'            => '0.92';
test_requires 'Test::Differences'     => '0.4801';
test_requires 'Test::Deep'            => '0.103';
test_requires 'Catalyst::Test'        => 0;
test_requires 'HTTP::Request::Common' => '5.824';
test_requires 'FindBin'               => 0;
test_requires 'Path::Class'           => '0.16';
test_requires 'Data::Dumper'          => 0;

author_requires 'Test::Pod'           => '1.22';
author_requires 'Test::Pod::Coverage' => '1.08';
author_requires 'Pod::Coverage'       => '0.18';
author_requires 'Test::Perl::Critic'  => '1.01';

extra_tests;

auto_install;

install_share;

WriteAll;
