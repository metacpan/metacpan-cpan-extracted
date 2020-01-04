use inc::Module::Install;

name 'DateTime-Format-GeekTime';
all_from 'lib/DateTime/Format/GeekTime.pm';

requires 'DateTime' => 0;
requires 'Carp' => 0;

WriteAll;
