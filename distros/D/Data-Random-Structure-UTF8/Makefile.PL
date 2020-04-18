use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /^push_to_GIT$/; # SKIP
    return $file;
}

my %WriteMakefileArgs = (
#INSTALL_BASE => "$ENV{HOME}/usr",
    NAME             => 'Data::Random::Structure::UTF8',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Data/Random/Structure/UTF8.pm',
    ABSTRACT_FROM    => 'lib/Data/Random/Structure/UTF8.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.8.0',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Scalar::Util' => '0',
	'Data::Dump' => '0',
	'Data::Dumper' => '0',
    },
    PREREQ_PM => {
	'Scalar::Util' => '0',
	'Data::Random::Structure' => '0',
    },
 	# Thanks to marto @ Perlmonks.org
	# see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
    META_MERGE => {
        'meta-spec' => { version => 2 },
	requires    => { perl    => '5.10.0' },
        resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/Data::Random::Structure::UTF8',
            repository => {
                url  => 'https://github.com/hadjiprocopis/Data-Random-Structure-UTF8',
                web  => 'https://github.com/hadjiprocopis/Data-Random-Structure-UTF8',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/Data-Random-Structure-UTF8/issues',
            }
        },
    },

   dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Random-Structure-UTF8-*' },
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
