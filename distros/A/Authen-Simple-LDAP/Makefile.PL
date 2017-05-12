use strict;
use inc::Module::Install;

name           'Authen-Simple-LDAP';
all_from       'lib/Authen/Simple/LDAP.pm';
readme_from    'lib/Authen/Simple/LDAP.pm';
repository     'http://github.com/chansen/p5-authen-simple-ldap';

requires       'Authen::Simple' => '0';
requires       'Net::LDAP'      => '0';

tests 't/*.t t/*/*.t';

WriteAll;

