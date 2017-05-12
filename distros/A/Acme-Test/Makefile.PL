use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Acme::Test',
    VERSION_FROM    => 'lib/Acme/Test.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 'Test::More' => 0, 'Module::Load' => 0 },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => '100% test coverage, all the time'
);             
