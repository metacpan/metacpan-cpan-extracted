use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Bundle::Maintainer::MHASCH',
    VERSION_FROM      => 'lib/Bundle/Maintainer/MHASCH.pm',
    PREREQ_PM         => {},
    BUILD_REQUIRES    => {
            'ExtUtils::MakeMaker' => '6.56',
            'Test::More'          => '0.75',
        },
    MIN_PERL_VERSION  => '5.006',
    ABSTRACT_FROM     => 'lib/Bundle/Maintainer/MHASCH.pm',
    AUTHOR            => 'Martin Becker <mhasch at cpan.org>',
    SIGN              => 1,
    LICENSE           => 'perl_5',
);
