use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Bundle::CPANPLUS::Test::Reporter',
    VERSION_FROM    => 'lib/Bundle/CPANPLUS/Test/Reporter.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Bundle to install all modules required & desired by '.
	                   'CPANPLUS to provide automated test reporting to '.
	                   'C<testers.cpan.org>'
);    
