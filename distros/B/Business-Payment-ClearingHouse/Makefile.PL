use inc::Module::Install;

name     'Business-Payment-ClearingHouse';
all_from 'lib/Business/Payment/ClearingHouse.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Moose' => '0.92';
requires 'Data::UUID' => '1.202';

WriteAll;

