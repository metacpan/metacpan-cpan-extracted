use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'DBIx::Class::ResultSet::PrettyPrint',
    AUTHOR           => q{Paul Cochrane <paul@peateasea.de>},
    VERSION_FROM     => 'lib/DBIx/Class/ResultSet/PrettyPrint.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Class/ResultSet/PrettyPrint.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'    => '0',
        'Capture::Tiny' => '0',
      },
    PREREQ_PM => {
        'Text::Table::Tiny' => '0',
        'DBIx::Class'       => '0',
        'SQL::Translator'   => '0.11018',
    },
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git@github.com:paultcochrane/DBIx-Class-ResultSet-PrettyPrint.git',
                web => 'https://github.com/paultcochrane/DBIx-Class-ResultSet-PrettyPrint',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Class-ResultSet-PrettyPrint-*' },
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
