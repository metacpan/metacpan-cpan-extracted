use inc::Module::Install;

name 'CatalystX-Menu-mcDropdown';
all_from 'lib/CatalystX/Menu/mcDropdown.pm';

requires 'Catalyst::Runtime';
requires 'MRO::Compat';
requires 'HTML::Entities';
requires 'HTML::Element';
requires 'CatalystX::Menu::Tree', '0.02';
test_requires 'Test::More';

WriteAll();
