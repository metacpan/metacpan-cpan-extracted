# -*- mode: perl; eval: (follow-mode) -*-
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::gqmt',
    ABSTRACT_FROM    => 'lib/App/gqmt.pm',
    VERSION_FROM     => 'lib/App/gqmt.pm',
    EXE_FILES        => [ 'gqmt' ],
    AUTHOR           => 'Zeus Panchenko <zeus@gnu.org.ua>',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => 5.016001,
    PREREQ_PM        => {
	'Data::Printer'      => '0.38',
	    'File::Basename' => '2.00',
	    'Getopt::Long'   => '2.00',
	    'JSON'           => '2.00',
	    'LWP::UserAgent' => '6.00',
	    'Pod::Usage'     => '1.00',
	    'Time::Piece'    => '1.05',
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
	'meta-spec' => { version => 2 },
	    resources   => {
		repository => {
		    type => 'git',
		    url  => 'ssh://git@github.com:z-eos/gqmt.git',
		    web  => 'https://github.com/z-eos/gqmt.git',
		},
	}})
     : ()
    ),
    );
