use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/C/Tokenize.pm';
my $pod = 'lib/C/Tokenize.pod';
my $repo = 'https://github.com/benkasminbullock/C-Tokenize';

WriteMakefile (
    NAME => 'C::Tokenize',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Carp' => '0',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    # This module uses named captures, so it requires Perl 5.10.
    MIN_PERL_VERSION => '5.010001',
);
