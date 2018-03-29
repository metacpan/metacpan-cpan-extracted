use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/C/Utility.pm';
my $pod = 'lib/C/Utility.pod';
my $repo = 'https://github.com/benkasminbullock/C-Utility';

WriteMakefile (
    NAME => 'C::Utility',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    EXE_FILES => ['script/make-c-text'],
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'File::Versions' => 0,
	'File::Spec' => 0,
	'File::Slurper' => '0.012',
	'C::Tokenize' => '0.18',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    # Passes 5.6.2 at CPANTESTERS as of version 0.003.
    MIN_PERL_VERSION => '5.006001',
);
