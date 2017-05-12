use strict;
use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-Plugin-FormValidator';
author 'Sebastian Riedel (sri@oook.de)';
all_from 'lib/Catalyst/Plugin/FormValidator.pm';
requires 'Catalyst'            => '5.8';
requires 'Data::FormValidator' => 0;
requires 'MRO::Compat';
requires 'Moose'               => '0.93';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';
author_tests 't/author';

WriteAll;
