use inc::Module::Install;

name     'Catalyst-View-TT-ForceUTF8';
all_from 'lib/Catalyst/View/TT/ForceUTF8.pm';
requires 'Catalyst'                     => 5.5;
requires 'Catalyst::View::TT'           => 0.22;
requires 'Template::Provider::Encoding' => 0.09;
auto_install;
WriteAll;
