use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CPAN::Reporter::Smoker::Safer',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/CPAN/Reporter/Smoker/Safer.pm',
    ABSTRACT_FROM       => 'lib/CPAN/Reporter/Smoker/Safer.pm',
    PREREQ_PM => {
	'CPAN'                   => 0,
	'CPAN::Reporter'         => 0,
	'CPAN::Reporter::Smoker' => 0,
	'Test::More'             => 0,
	'Test::Differences'      => 0,
        'URI'                    => 0,
        'LWP::Simple'            => 0,
	'CPAN::DistnameInfo'     => 0,
	'File::Temp'             => 0,
	'Date::Calc'             => 0,
	'CPAN::Reporter::History' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPAN-Reporter-Smoker-Safer-*' },
);
