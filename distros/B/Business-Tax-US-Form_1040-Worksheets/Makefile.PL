use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Business::Tax::US::Form_1040::Worksheets',
    VERSION_FROM        => 'lib/Business/Tax/US/Form_1040/Worksheets.pm',
    AUTHOR              => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT_FROM       => 'lib/Business/Tax/US/Form_1040/Worksheets.pm',
    LICENSE             => 'perl_5',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'Test::Simple' => 0.44,
    },
    test                => { TESTS => "t/*.t t/20??/*.t" },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        #resources => {
        #    homepage    => undef,
        #    repository  => {
        #        url         => undef,
        #        web         => undef,
        #        type        => undef,
        #    },
        #    bugtracker => {
        #        web         => undef,
        #    },
        #},
    })),
);

WriteMakefile(%WriteMakefileArgs);
