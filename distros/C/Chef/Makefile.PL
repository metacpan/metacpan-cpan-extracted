use inc::Module::Install;

name     'Chef';
all_from 'lib/Chef.pm';
author   'Adam Jacob <adam@opscode.com>';
license  'perl';

build_requires 'Test::More';
requires 'Moose';
requires 'JSON::Any';

auto_install;

WriteAll;

