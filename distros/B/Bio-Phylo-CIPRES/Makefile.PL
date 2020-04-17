use strict;
use warnings;
 
use 5.008;
 
use ExtUtils::MakeMaker;
WriteMakefile
(
    NAME          => 'Bio::Phylo::CIPRES',
    AUTHOR        => 'Rutger Vos <rutgeraldo@gmail.com>',
    VERSION_FROM  => 'lib/Bio/Phylo/CIPRES.pm',
    ABSTRACT_FROM => 'lib/Bio/Phylo/CIPRES.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'XML::Twig'      => '0',
		'YAML'           => '0',
        'Bio::Phylo'     => '0',
        'URI'            => '0',
        'LWP::UserAgent' => '0',	
    },
    TEST_REQUIRES => {
          'Test::More' => '0'
    },
    EXE_FILES => [
           'script/cipresrun'
    ],
    META_MERGE    => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/naturalis/bio-cipres.git',
                 web  => 'https://github.com/naturalis/bio-cipres',
             },
             bugtracker => {web => 'https://github.com/naturalis/bio-cipres/issues'},
         },
    }, 
);
