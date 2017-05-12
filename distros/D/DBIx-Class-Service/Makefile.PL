use strict;
use warnings;
use inc::Module::Install;

name('DBIx-Class-Service');
author('Toru Yamaguchi <zigorou@cpan.org>');
all_from('lib/DBIx/Class/Service.pm');
license('perl');

requires('Carp::Clan');
requires('Class::Inspector');
requires('DBIx::Class');
requires('Module::Find');

build_requires('DBIx::Class::TimeStamp');
build_requires('DBICx::TestDatabase');

use_test_base;

auto_include;
auto_install;

WriteAll;
