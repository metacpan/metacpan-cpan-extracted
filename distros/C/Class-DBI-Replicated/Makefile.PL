use strict;
use warnings;

use inc::Module::Install;

name   'Class-DBI-Replicated';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
perl_version '5.006';
all_from;

build_requires 'Test::More'          => 0;

requires 'Class::DBI'                => '3.0.1';
requires 'Params::Validate'          => '0.74';
requires 'Class::Data::Inheritable'  => 0;
requires 'Class::Accessor::Class'    => 0;
requires 'Sub::Install'              => 0;

recommends 'Class::DBI::mysql'       => 0;
recommends 'Class::DBI::Pg'          => 0;

auto_install;

WriteAll;
