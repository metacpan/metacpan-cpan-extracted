use strict;
use warnings;
use inc::Module::Install;

name	 'Data-ResultSet';
all_from 'lib/Data/ResultSet.pm';

test_requires 'Test::More' => 0;
test_requires 'Test::Exception' => 0;
test_requires 'Test::MockObject' => 0;

author_tests('xt');  # Uses Module::Install::AuthorTests

WriteAll;
