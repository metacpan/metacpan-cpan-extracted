#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' 			=> 'CGI::Graph',
	'DISTNAME'		=> 'CGIGraph',
	'VERSION_FROM'		=> 'lib/CGI/Graph.pm',

        ($] >= 5.005 ?
		('ABSTRACT' => 'Create interactive CGI-based graphs',
                 'AUTHOR'   => 'Max Chang <chang@gnf.org>'):()
        ),

	'PREREQ_PM'		=> 	
		{ 	'GD' 	=> undef,
			'GD::Graph' => undef,
		   	'CGI'   => undef,
			'Data::Table'  => undef},

        'dist' 			=> 
                { 	'COMPRESS'              => 'gzip -9f',
                        'SUFFIX'                => 'gz'}
);
