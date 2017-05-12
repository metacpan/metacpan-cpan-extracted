use 5.006;
use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'Class::DataStore',
	'VERSION_FROM'  => 'lib/Class/DataStore.pm',
	'ABSTRACT_FROM' => 'lib/Class/DataStore.pm',
	'PREREQ_PM'     => {},
	'AUTHOR'        => 'Eric Folley <eric@folley.net>',
);
