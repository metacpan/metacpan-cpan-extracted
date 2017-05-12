use strict;
use warnings;
use inc::Module::Install;

name	 'Data-ResultSet';
all_from 'lib/Data/ResultSet.pm';

build_requires 'Test::More' => 0;
build_requires 'Test::Exception' => 0;
build_requires 'Test::MockObject' => 0;

author_tests('xt');  # Uses Module::Install::AuthorTests

auto_install;
WriteAll;
