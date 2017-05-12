use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Test::Tapat',
    AUTHOR              => 'Jeremiah C. Foster <jeremiah@cpan.org>',
    VERSION_FROM        => 'lib/App/Test/Tapat.pm',
    ABSTRACT_FROM       => 'lib/App/Test/Tapat.pm',
    INSTALLDIRS         => 'site',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Moose'      => 0,
	'TAP::Harness' => 0,
	'TAP::Parser' => 0,
	'TAP::Parser::Aggregator' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Test-Tapat-*' },
);
