use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'CPANPLUS::Dist::PAR',
    VERSION_FROM    => 'lib/CPANPLUS/Dist/PAR.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => {    'Test::More'                => 0, 
                            'CPANPLUS'                  => 0.074,
                            'CPANPLUS::Dist::Build'     => '0.04',
                            'PAR::Dist'                 => 0.19,
                            'Params::Check'             => 0,
                            'Module::Load::Conditional' => 0,
                            'Locale::Maketext::Simple'  => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Create PAR distributions from CPANPLUS'
); 

