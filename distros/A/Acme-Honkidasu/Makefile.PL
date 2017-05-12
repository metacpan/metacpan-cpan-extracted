use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::ReadmePodFromPod;
name 'Acme-Honkidasu';
all_from 'lib/Acme/Honkidasu.pm';
readme_pod_from 'lib/Acme/Honkidasu.pm';

requires 'Time::Piece' => '1.20';
requires 'POSIX::strftime::GNU';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
