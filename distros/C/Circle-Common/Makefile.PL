use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'config';

my %WriteMakefileArgs = (
    NAME               => 'Circle::Common',
    AUTHOR             => q{charles li <lidh04@gmail.com>},
    VERSION_FROM       => 'lib/Circle/Common.pm',
    ABSTRACT_FROM      => 'lib/Circle/Common.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'LWP::UserAgent'          => '6.67',
        'LWP::Protocol::https'    => '6.14',
        'YAML'                    => '1.30',
        'Slurp'                   => '0.4',
        'Try::Tiny'               => '0.31',
        'JSON'                    => '4.10',
        'URL::Encode'             => '0.03',
        'File::ShareDir::Install' => '0.14',
        'File::Share'             => '0.27',
    },
    test  => { TESTS    => 't/*.t t/*/*.t' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Circle-Common-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
  unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

package MY;
use File::ShareDir::Install 'postamble';
