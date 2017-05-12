use inc::Module::Install;

name 'Catalyst-Model-Orochi';
all_from 'lib/Catalyst/Model/Orochi.pm';

requires 'Catalyst', 5.8;
requires 'Orochi';

tests 't/*.t';
readme_from 'lib/Catalyst/Model/Orochi.pm';
WriteAll;