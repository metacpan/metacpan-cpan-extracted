#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'AI::FANN::Evolving',
	'ABSTRACT_FROM' => 'lib/AI/FANN/Evolving.pm',
	'VERSION_FROM'  => 'lib/AI/FANN/Evolving.pm',
	'EXE_FILES'     => [ 'script/aivolver' ],
	'AUTHOR'        => 'Rutger Vos <rutger.vos@naturalis.nl>',
	'PREREQ_PM'     => { 	
		'AI::FANN' => 0,
		'Algorithm::Genetic::Diploid' => 0,	
	},
);
