use inc::Module::Install;

name 'Catalyst-View-CSS-Squish';
all_from 'lib/Catalyst/View/CSS/Squish.pm';

requires Catalyst => '5.64';
requires CSS::Squish;

auto_install;
WriteAll;
