use inc::Module::Install;
name 'Cache-Isolator';
all_from 'lib/Cache/Isolator.pm';

requires 'Try::Tiny', 0.09;
requires 'List::Util';
requires 'Time::HiRes';
requires 'Class::Accessor::Lite';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::TCP';
test_requires 'Test::Skip::UnlessExistsExecutable';
test_requires 'Cache::Memcached::Fast';
test_requires 'File::Which';
test_requires 'Proc::Guard';

auto_set_repository;
WriteAll;
