use strict;
use warnings;
use inc::Module::Install;

name 'Acme-Replica';
all_from      'lib/Acme/Replica.pm';
author        'Kei Shimada <sasakure_kei@cpan.org>',
test_requires 'Test::More';
test_requires 'Test::Exception';

WriteAll;
