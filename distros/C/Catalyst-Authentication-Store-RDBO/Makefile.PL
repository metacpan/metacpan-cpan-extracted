use inc::Module::Install;

name 'Catalyst-Authentication-Store-RDBO';
all_from 'lib/Catalyst/Authentication/Store/RDBO.pm';
author q{Dave O'Neill <dmo@dmo.ca>};

requires(
    'Catalyst::Runtime'                => 0,
    'Catalyst::Plugin::Authentication' => '0.10006',
    'Rose::DB::Object'                 => 0,
);

test_requires 'Test::More';

extra_tests;

auto_install;

WriteAll;

