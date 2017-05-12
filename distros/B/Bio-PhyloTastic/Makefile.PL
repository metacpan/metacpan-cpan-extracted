#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Bio-PhyloTastic',
    'AUTHOR'       => 'Rutger Vos',
    'PL_FILES'     => { 'script/phylotastic.PL' => 'script/phylotastic' },
    'EXE_FILES'    => [],
    'VERSION_FROM' => 'lib/Bio/PhyloTastic.pm',
    'LICENSE'      => 'perl',
    'clean'        => {},    
    'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
	'PREREQ_PM'    => {
		'Bio::Phylo'     => '0.50',
		'LWP::UserAgent' => 0,
		'URI::Escape'    => 0,
		'Scalar::Util'   => 0,
		'XML::Twig'      => 0,
		'XML::XML2JSON'  => 0,
		'JSON'           => 0,
	}
);