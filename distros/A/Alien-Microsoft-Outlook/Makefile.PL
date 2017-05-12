use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

die "No support for OS" if $^O !~ m/Win/;

WriteMakefile(
    NAME             => 'Alien::Microsoft::Outlook',
    AUTHOR           => q{Duncan Garland <duncan@cpan.org>},
    VERSION_FROM     => 'lib/Alien/Microsoft/Outlook.pm',
    ABSTRACT_FROM    => 'lib/Alien/Microsoft/Outlook.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'Win32::OLE'              => 0,
        'Win32::OLE::Const'       => 0,
    },
    # dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Alien-Microsoft-Outlook-*' },
);
