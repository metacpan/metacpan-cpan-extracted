sub auto_set_repository {}

use inc::Module::Install;
name 'Array-Diff';
all_from 'lib/Array/Diff.pm';

test_requires 'Test::More';

requires 'Algorithm::Diff' => '1.19';
requires 'Class::Accessor::Fast';

recommends 'Algorithm::Diff::XS';

use_test_base;
auto_set_repository;

WriteAll;
