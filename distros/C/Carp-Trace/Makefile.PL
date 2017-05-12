use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Carp::Trace',
    VERSION_FROM    => 'lib/Carp/Trace.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 'Test::More'               => 0, 
                         'Devel::Caller::Perl'      => 0,   
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Simple caller() trace'
);             
