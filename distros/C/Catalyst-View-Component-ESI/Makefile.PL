use inc::Module::Install;

name          'Catalyst-View-Component-ESI';
all_from      'lib/Catalyst/View/Component/ESI.pm';

requires 'Catalyst::Runtime' => '5.70000';
requires 'Moose';
requires 'Moose::Role';
requires 'LWP::UserAgent';

catalyst;

auto_install;
WriteAll;

