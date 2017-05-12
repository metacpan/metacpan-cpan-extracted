
use inc::Module::Install;

name 'DBIx-Romani';
abstract 'Romani is a SQL and database abstraction layer, inspired by Creole, which aims to help adapt to the differences in SQL dialects';
author 'David Snopek';
version '@XMLDOOM_VERSION';
license 'gpl';

build_requires 'Test::More';
build_requires 'Test::Class';
build_requires 'Data::Dumper';
build_requires 'Carp';
requires 'DBI';
requires 'Exception::Class';
requires 'Exception::Class::DBI';
requires 'XML::DOM';
requires 'Data::Dumper';

no_index directory => 'test';

if ( $ARGV[0] ne 'dist' )
{
	auto_install;
}

WriteAll;

