#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'Algorithm::Genetic::Diploid',
	'ABSTRACT_FROM' => 'lib/Algorithm/Genetic/Diploid.pm',
	'AUTHOR'        => 'Rutger Vos <rutger.vos@naturalis.nl>',
	'PREREQ_PM'     => { 'YAML::Any' => 0 },
	'VERSION_FROM'  => 'lib/Algorithm/Genetic/Diploid.pm',
);