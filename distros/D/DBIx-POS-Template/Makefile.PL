use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::POS::Template',
    AUTHOR           => q{Михаил Че (Mikhail Che) <mche@cpan.org>},
    VERSION_FROM     => 'lib/DBIx/POS/Template.pm',
    ABSTRACT_FROM    => 'lib/DBIx/POS/Template.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Pod::Parser' => 1.60,
        'Text::Template' => 1.46,
        'Hash::Merge'=>0.200,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #clean => { FILES => 'DBIx-POS-Template-*' },
);
