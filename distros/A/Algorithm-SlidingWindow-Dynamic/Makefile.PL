use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Algorithm::SlidingWindow::Dynamic',
    VERSION_FROM => 'lib/Algorithm/SlidingWindow/Dynamic.pm',
    ABSTRACT     => 'Generic, dynamically sized sliding window',
    AUTHOR       => 'Joshua Day',
    LICENSE      => 'perl',

    MIN_PERL_VERSION => '5.10.1',

    PREREQ_PM => {
        'Carp'       => 0,
        'Test::More' => 0,
    },

    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-algorithm-slidingwindow-dynamic.git',
                web  => 'https://github.com/haxmeister/perl-algorithm-slidingwindow-dynamic',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-algorithm-slidingwindow-dynamic/issues',
            },
        },
    },
);
