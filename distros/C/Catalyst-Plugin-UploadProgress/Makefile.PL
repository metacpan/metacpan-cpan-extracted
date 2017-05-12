use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-Plugin-UploadProgress';
all_from 'lib/Catalyst/Plugin/UploadProgress.pm';

requires 'Catalyst::Runtime' => '5.90017';
requires 'Moose';
requires 'MooseX::RelatedClassRoles';
requires 'namespace::autoclean';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::NoTabs';
author_tests 't/author';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-UploadProgress/';

WriteAll;
