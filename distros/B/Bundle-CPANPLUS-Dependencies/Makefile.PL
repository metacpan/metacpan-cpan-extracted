use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Bundle::CPANPLUS::Dependencies',
    VERSION_FROM    => 'lib/Bundle/CPANPLUS/Dependencies.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Bundle to install all modules required & desired by '.
	                   'CPANPLUS'
);    
