use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'data';

# Optional except for cpancover, cpantesters etc.
my $extra_test =
  ( $ENV{EXTENDED_TESTING} || $ENV{AUTOMATED_TESTING} )
  ? 'requires'
  : 'recommends';

my %WriteMakefileArgs = (
    NAME               => 'Benchmark::DKbench',
    AUTHOR             => q{Dimitrios Kechagias <dkechag@cpan.org>},
    VERSION_FROM       => 'lib/Benchmark/DKbench.pm',
    ABSTRACT_FROM      => 'lib/Benchmark/DKbench.pm',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.12.0',
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker"     => '6.52',
        "File::ShareDir::Install" => 0,
    },
    EXE_FILES     => ["dkbench", "setup_dkbench"],
    TEST_REQUIRES => {
        'Test2::Tools::Exception' => '0',
        'Test2::V0'               => '0',
    },
    PREREQ_PM => {
        'Astro::Coord::Constellations'   => '0',
        'Astro::Coord::Precession'       => '0',
        'Crypt::JWT'                     => '0.032',
        'CSS::Inliner'                   => '0',
        'DateTime'                       => '0',
        'DBD::Mock'                      => '0',
        'DBI'                            => '0',
        'File::ShareDir'                 => '0',
        'HTML::FormatText'               => '0',
        'HTML::Parser'                   => '0',
        'HTML::TreeBuilder'              => '0',
        'Imager'                         => '1',
        'Image::PHash'                   => '0.3',
        'JSON::XS'                       => '0',
        'Math::MatrixReal'               => '0',
        'Math::DCT'                      => '0',
        'Moose'                          => '0',
        'MCE::Loop'                      => '0',
        'SQL::Inserter'                  => '0',
        'SQL::Abstract::Classic'         => '0',
        'System::Info'                   => '0',
        'Test::Harness'                  => '0',
        'Test::Requires'                 => '0',
        'Text::Levenshtein::XS'          => '0',
        'Text::Levenshtein::Damerau::XS' => '0',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        prereqs => {
            test => {
                $extra_test => {
                    'Test::MockFile' => '0',
                }
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/dkechag/Benchmark-DKbench.git',
                web  => 'https://github.com/dkechag/Benchmark-DKbench',
            },
        },
    },
    clean => {FILES => 'Benchmark-DKbench-*'},
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

package MY;
use File::ShareDir::Install 'postamble';
