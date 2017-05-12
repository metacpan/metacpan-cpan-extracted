use inc::Module::Install;

name        'Catalyst-Plugin-StripScripts';
all_from    'lib/Catalyst/Plugin/StripScripts.pm';

requires    'HTML::StripScripts::Parser' => '0';

WriteAll;
