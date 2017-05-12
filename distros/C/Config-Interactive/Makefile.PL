use inc::Module::Install;

name             'Config-Interactive';
author_from      'lib/Config/Interactive.pm';
license          'Fermitools';
version          '0.04';
perl_version     '5.0061';
all_from 	 'lib/';

 
requires 'Test::More' => 0; 
requires 'fields' => 0; 
requires 'Data::Dumper' => 0;
requires 'XML::Simple' => 0;
requires 'XML::Parser' => 0;

no_index directory  => 't';

auto_install;
WriteAll;
