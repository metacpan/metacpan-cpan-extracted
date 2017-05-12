use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'CPANPLUS::Daemon',
    VERSION_FROM    => 'lib/CPANPLUS/Daemon.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 
                        'Getopt::Std'               => 0,
                        'Test::More'                => 0, 
                        'POE'                       => 0,
                        'CPANPLUS'                  => '0.081',
                        'IO::String'                => 0,
                        'Locale::Maketext::Simple'  => 0,
                        'Params::Check'             => '0.22',
                        'Object::Accessor'          => '0.02',
                    },
    EXE_FILES       => [ qw|bin/cpanpd| ],                    
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Remote CPANPLUS Administration Daemon'
);     
