use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ACME::MSDN::SPUtility',
    AUTHOR              => 'BlueT - Matthew Lien - 練喆明 <BlueT@BlueT.org>',
    VERSION_FROM        => 'lib/ACME/MSDN/SPUtility.pm',
    ABSTRACT_FROM       => 'lib/ACME/MSDN/SPUtility.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'	=> 0,
		'Perl6::Say'	=> '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ACME-MSDN-SPUtility-*' },
);
