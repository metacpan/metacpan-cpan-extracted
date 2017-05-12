use inc::Module::Install;

name 'Catalyst-Plugin-Geography';
all_from 'lib/Catalyst/Plugin/Geography.pm';

requires 'IP::Country::Fast';
requires 'Geography::Countries';
requires 'Class::Accessor::Fast';

WriteAll;