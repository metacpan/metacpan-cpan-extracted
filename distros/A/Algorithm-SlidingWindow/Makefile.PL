use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Algorithm::SlidingWindow',
    DISTNAME     => 'Algorithm-SlidingWindow',
    VERSION_FROM => 'lib/Algorithm/SlidingWindow.pm',
    ABSTRACT     => 'Fixed-capacity sliding window (overwrite-oldest)',
    AUTHOR       => 'Joshua S. Day',
    LICENSE      => 'perl',

    PREREQ_PM    => {},

    TEST_REQUIRES => {
        'Test::More'   => 0,
        'Scalar::Util' => 0,
    },

     # Metadata consumed by MetaCPAN
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-algorithm-slidingwindow.git',
                web  => 'https://github.com/haxmeister/perl-algorithm-slidingwindow',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-algorithm-slidingwindow/issues',
            },
            homepage => 'https://github.com/haxmeister/perl-algorithm-slidingwindow',
        },
    },

);
