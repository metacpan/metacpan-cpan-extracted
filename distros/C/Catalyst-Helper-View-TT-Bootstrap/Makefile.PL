use inc::Module::Install;

name 'Catalyst-Helper-View-TT-Bootstrap';
all_from 'lib/Catalyst/Helper/View/TT/Bootstrap.pm';

# Standard Modules 
requires 'Catalyst::Devel';
requires 'Catalyst::View::TT';

auto_install;
WriteAll;
