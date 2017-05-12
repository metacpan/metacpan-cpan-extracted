use strict;
use warnings;
use ExtUtils::MakeMaker;

my $name = 'Data::Kanji::Kanjidic';
my $pm = "lib/Data/Kanji/Kanjidic.pm";
my $pod = "lib/Data/Kanji/Kanjidic.pod";
my $repo = "https://github.com/benkasminbullock/Data-Kanji-Kanjidic";

WriteMakefile (
    NAME => $name,
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    PREREQ_PM => {
	Encode => 0,
	Carp => 0,
    },
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006001',
);
