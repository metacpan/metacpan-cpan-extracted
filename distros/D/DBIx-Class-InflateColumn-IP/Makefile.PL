use strict;
use warnings;
use 5.008001;
use inc::Module::Install 1.05;

name 'DBIx-Class-InflateColumn-IP';
license 'perl';
perl_version '5.008001';
all_from 'lib/DBIx/Class/InflateColumn/IP.pm';

requires 'DBIx::Class'  => 0.07005;
requires 'NetAddr::IP';

readme_from 'lib/DBIx/Class/InflateColumn/IP.pm';
clean_files 'README';

resources repository => 'git://git.shadowcat.co.uk/dbsrgits/DBIx-Class-InflateColumn-IP.git';

WriteAll;
