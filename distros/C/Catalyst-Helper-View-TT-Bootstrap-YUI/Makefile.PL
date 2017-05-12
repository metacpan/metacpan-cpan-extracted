use inc::Module::Install;

name 'Catalyst-Helper-View-TT-Bootstrap-YUI';
all_from 'lib/Catalyst/Helper/View/TT/Bootstrap/YUI.pm';

# Standard Modules 
requires 'Catalyst::Helper';
requires 'Catalyst::View::TT';
requires 'DateTime';

auto_install;
WriteAll;
