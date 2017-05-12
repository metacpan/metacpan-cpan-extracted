use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Curses::Marquee',
    AUTHOR              => 'Shawn Boyette <mdxi@cpan.org>',
    VERSION_FROM        => 'lib/Acme/Curses/Marquee.pm',
    ABSTRACT_FROM       => 'lib/Acme/Curses/Marquee.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Curses'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Curses-Marquee-*' },
);
