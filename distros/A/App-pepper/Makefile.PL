#!/usr/bin/perl
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	'NAME'			=> 'App::pepper',
	'VERSION_FROM'	=> 'lib/App/pepper.pm',
	'VERSION_FROM'	=> 'lib/App/pepper.pm',
	'AUTHOR'		=> [ 'Gavin Brown <gavin.brown@fastmail.uk>' ],
	'LICENSE'		=> 'perl',
	'EXE_FILES'		=> [ 'pepper' ],
	'PREREQ_PM'		=> {
		'File::Temp'        => 0,
		'Getopt::Long'      => 0,
		'HTML::Entities'    => 0,
		'Mozilla::CA'       => 0,
		'Net::EPP'          => '0.24',
		'Pod::Usage'        => 0,
		'Term::ANSIColor'   => 0,
		'Term::ReadLine'    => 0,
		'Text::ParseWords'  => 0,
		'XML::LibXML'       => 0,
		'XML::Parser'       => 0,
	},
	'META_MERGE' 	=> {
        'meta-spec' => { 'version' => 2 },
         'resources' => {
             'repository' => {
                 'type' => 'git',
                 'url'  => 'https://github.com/gbxyz/pepper.git',
                 'web'  => 'https://github.com/gbxyz/pepper',
             },
             'bugtracker' => {
                 'web' => 'https://github.com/gbxyz/pepper/issues',
             },
         },
    },
);

my $have_trg;
eval qw(
	use Term::ReadLine::Gnu;
	$have_trg = 1;
);
if (!$have_trg) {
	print STDERR "Warning: optional prerequisite Term::ReadLine::Gnu 0 not found.\n";
}