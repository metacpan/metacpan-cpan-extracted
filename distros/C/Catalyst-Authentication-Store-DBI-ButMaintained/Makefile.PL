use inc::Module::Install;

name     'Catalyst-Authentication-Store-DBI-ButMaintained';
all_from 'lib/Catalyst/Authentication/Store/DBI/ButMaintained.pm';
author   q{Evan Carroll <me@evancarroll.com>};
license  'perl';

build_requires 'Test::More';

requires 'Catalyst::Plugin::Authentication';
requires 'MooseX::Types::LoadableClass';
requires 'Catalyst::Model::DBI';
requires 'Storable';
requires 'Moose' => 0.98;

recommends 'Catalyst::Plugin::Authorization::Roles';

resources(
	'homepage'     => 'http://www.evancarroll.com/'
	, 'repository' => 'git://github.com/EvanCarroll/Catalyst-Authentication-Store-DBI.git'
);


auto_install;

WriteAll;
