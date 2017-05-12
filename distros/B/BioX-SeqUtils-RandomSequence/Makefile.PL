use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BioX::SeqUtils::RandomSequence',
    AUTHOR              => 'Roger A Hall <rogerhall@cpan.org>',
    VERSION_FROM        => 'lib/BioX/SeqUtils/RandomSequence.pm',
    ABSTRACT            => 'Create random nucleotide and protein sequences.',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'             => 0,
        'version'                => 0,
    	'Bio::Tools::CodonTable' => 0, 
	'Class::Std'             => 0.0.9, 
	'Class::Std::Utils'      => 0.0.3,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BioX-SeqUtils-RandomSequence-*' },
);
