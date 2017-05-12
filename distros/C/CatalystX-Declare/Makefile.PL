#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 1.00;
use Module::Install::AuthorTests;
use Module::Install::AutoManifest;
use Module::Install::ProvidesClass;
use Module::Install::Repository;
use Module::Install::Homepage;

name            'CatalystX-Declare';
author          'Robert Sedlacek <rs@474.at>';
version         '0.015';

all_from        'lib/CatalystX/Declare.pm';
readme_from     'lib/CatalystX/Declare.pm';

requires        'Carp';
requires        'FindBin';
requires        'Class::Inspector',                 '1.24';
requires        'Perl6::Junction',                  '1.40000';
requires        'aliased',                          '0.30';
requires        'parent',                           '0.221';
requires        'Data::Dump',                       '1.14';
requires        'Catalyst',                         '5.80025';
requires        'CLASS',                            '1.00';
requires        'Devel::Declare',                   '0.006000';
requires        'Moose',                            '1.14';
requires        'MooseX::Declare',                  '0.34';
requires        'MooseX::MethodAttributes',         '0.24';
requires        'MooseX::Role::Parameterized',      '0.19';
requires        'MooseX::Types',                    '0.24';
requires        'MooseX::Method::Signatures',       '0.36';
requires        'Catalyst::Controller::ActionRole', '0.15';
requires        'Data::Pond',                       '0.002';

test_requires   'Test::More',                       '0.96';
test_requires   'Test::Output',                     '0.16';
test_requires   'Catalyst::Test';
test_requires   'FindBin';

tests           't/*.t';
author_tests    'xt', 'examples/MyApp-Web/t';

auto_install;
auto_manifest;
auto_set_homepage;
auto_set_repository;
auto_provides_class;

WriteAll;
