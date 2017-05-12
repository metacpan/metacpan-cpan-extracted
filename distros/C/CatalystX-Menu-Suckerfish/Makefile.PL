use inc::Module::Install;

name 'CatalystX-Menu-Suckerfish';
all_from 'lib/CatalystX/Menu/Suckerfish.pm';

requires 'Catalyst::Runtime';
requires 'MRO::Compat';
requires 'HTML::Entities';
requires 'HTML::Element';
requires 'CatalystX::Menu::Tree';
test_requires 'Test::More';
no_index 'inc';

WriteAll();
