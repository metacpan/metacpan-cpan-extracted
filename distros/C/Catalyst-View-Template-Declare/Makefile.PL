use inc::Module::Install;

name 'Catalyst-View-Template-Declare';
all_from 'lib/Catalyst/View/Template/Declare.pm';
requires 'Catalyst::View::Templated';
requires 'Template::Declare' => '0.26';
requires 'Class::C3';
requires 'Module::Pluggable::Object';
requires 'PadWalker';

build_requires 'Test::More';
build_requires 'Catalyst::Runtime' => '5.7000';
auto_install;
WriteAll;
