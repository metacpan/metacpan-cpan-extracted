use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/CPAN/Nearest.pm';
my $pod = 'lib/CPAN/Nearest.pod';
my $repo = 'https://github.com/benkasminbullock/nearest-module';

WriteMakefile (
    NAME => 'CPAN::Nearest',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Text::Fuzzy' => '0.25',
	'Gzip::Faster' => '0.18',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.008000',
);
