use inc::Module::Install;

name 'Catalyst-TraitFor-Controller-LocaleSelect';
all_from 'lib/Catalyst/TraitFor/Controller/LocaleSelect.pm';

requires 'Catalyst::Runtime' => '5.80022';
requires 'MooseX::MethodAttributes::Role';
requires 'namespace::autoclean';

test_requires 'Test::More' => '0.88';

auto_install;
WriteAll;

