use 5.008008;
use ExtUtils::MakeMaker;
#see lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'    => 'DFA::Simple',
    'VERSION_FROM'      => 'lib/DFA/Simple.pm', # finds $VERSION
    PREREQ_PM         => {
                            'Carp' => 0.00,
                            'ExtUtils::MakeMaker' => '6.64',
                         }, # e.g., Module::Name => 1.1
    AUTHOR         => 'Randall Maas <randym@acm.org>',
    LICENSE        => 'perl_5',
    META_MERGE     => {
        resources => {
            repository => 'https://github.com//asb-capfan/DFA-Simple',
        },
    },
    MIN_PERL_VERSION => 5.008008,
);
