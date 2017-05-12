use 5.10.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'DBIx::Schema::Changelog',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/DBIx/Schema/Changelog.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.10.0,
    EXE_FILES          => ['bin/changelog-run'],
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    PREREQ_PM          => {
        'DBI'                          => 1.632,
        'DBD::SQLite'                  => 1.4,
        'File::Spec'                   => 0,
        'FindBin'                      => 0,
        'Getopt::Long'                 => 2.42,
        'Hash::MD5'                    => 0.08,
        'Moose'                        => 2.1403,
        'MooseX::HasDefaults::RO'      => 0,
        'MooseX::Types::LoadableClass' => 0.013,
        'MooseX::Types::Moose'         => 0.45,
        'MooseX::Types::PerlVersion'   => 0.002,
        'MooseX::Types::Path::Class'   => 0.06,
        'Time::Piece'                  => 1.27,
        'SQL::Abstract'                => 1.81,
        'YAML'                         => 1.13,
        'YAML::XS'                     => 0.55,
    },
    TEST_REQUIRES => {
        'Pod::Coverage::TrustPod' => 0,
        'Pod::Usage'              => 0,
        'Test::Cmd'               => 0,
        'Test::Exception'         => 0,
        'Test::CheckManifest'     => 0,
        'Test::Pod::Coverage'     => 0,
        'Test::Requires'          => 0,
        'Test::Spelling'          => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/GeoffreyDB/Geoffrey.git',
                web  => 'https://github.com/GeoffreyDB/Geoffrey',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'DBIx-Schema-Changelog-*' },
);
