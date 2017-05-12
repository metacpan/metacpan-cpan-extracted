use lib qw(inc);
use Devel::CheckLib;

# Prompt the user here for any paths and other configuration

check_lib_or_exit(
    # fill in what you prompted the user for here
    lib => [qw(z)]
);


use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/CPAN/Nearest.pm';
my $pod = 'lib/CPAN/Nearest.pod';
my $repo = 'https://github.com/benkasminbullock/nearest-module';

# Objects to link to.

#my $object = 'nearest-module.o Nearest.o';

#if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
#    $object .= ' text-fuzzy.o';
#    for my $type (qw/char int/) {
#	for my $algorithm ('', '-trans') {
#	    $object .= " edit-distance-$type$algorithm.o";
#	}
#    }
#}

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
#    OBJECT => $object,
#    LIBS => ['-lz',],
    MIN_PERL_VERSION => '5.008000',
);
