use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Data::Ref::JSON',
    VERSION_FROM        => 'lib/Data/Ref/JSON.pm',
    AUTHOR              => 'Jared Still (jkstill@gmail.com)',
	 #ABSTRACT            => 'Walk a referenced arbitrary data structure and provide the reference to access values',
	 ABSTRACT_FROM       => 'lib/Data/Ref/JSON.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
	 MIN_PERL_VERSION    => '5.006',
	 LICENSE             => 'mit',
    PREREQ_PM           => {
        'Test::Simple' => 0.44,
    },
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

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

