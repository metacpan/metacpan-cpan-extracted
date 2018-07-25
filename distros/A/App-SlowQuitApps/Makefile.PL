use strict;
use warnings;
use ExtUtils::MakeMaker;

os_unsupported if $^O ne 'darwin';

WriteMakefile(
    NAME                => 'App::SlowQuitApps',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/App/SlowQuitApps.pm',
    ABSTRACT_FROM       => 'lib/App/SlowQuitApps.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.010,
    PREREQ_PM => {
        'Test::More' => 0,
        'List::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-SlowQuitApps-*' },
);
