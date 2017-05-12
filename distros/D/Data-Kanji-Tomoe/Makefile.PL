use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Data/Kanji/Tomoe.pm';
my $pod = 'lib/Data/Kanji/Tomoe.pod';
my $repo = 'https://github.com/benkasminbullock/Data-Kanji-Tomoe';

WriteMakefile (
    NAME => 'Data::Kanji::Tomoe',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'XML::Parser' => '0',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.008001',
);
