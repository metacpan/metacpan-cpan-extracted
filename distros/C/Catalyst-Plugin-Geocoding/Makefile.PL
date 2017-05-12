use inc::Module::Install;

name        'Catalyst-Plugin-Geocoding';
all_from    'lib/Catalyst/Plugin/Geocoding.pm';

requires    'LWP' => '0';

WriteAll;
