use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Bundle::CPANPLUS',
    VERSION_FROM    => 'lib/Bundle/CPANPLUS.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => q[Bundle to install CPANPLUS and all it's dependencies],
);    
