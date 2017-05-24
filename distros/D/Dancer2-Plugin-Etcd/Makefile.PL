use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Dancer2::Plugin::Etcd',
    AUTHOR       => q{Sam Batschelet (sbatschelet) <sbatschelet@mac.com>},
    VERSION_FROM => 'lib/Dancer2/Plugin/Etcd.pm',
    ABSTRACT => 'Access to etcd v3 API via Dancer2',
    LICENSE  => 'perl',
    PL_FILES => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Class::Load'           => 0,
        'File::Spec'            => 0,
        'File::Temp'            => 0,
        'HTTP::Cookies'         => 0,
        'HTTP::Request::Common' => 0,
        'JSON'                  => 0,
        'Plack'                 => '1.0031',
        'Test::Exception'       => 0,
        'Test::More'            => 0,
    },
    PREREQ_PM => {
        'Etcd3'                 => '0.006',
        'Dancer2'               => '0.200000',
        'Dancer2::Core::Types'  => 0,
        'Dancer2::Plugin'       => 0,
        'Data::Structure::Util' => '0.16',
        'Moo'                   => '2.000',
        'namespace::clean'      => 0,
        'Scalar::Util'          => 0,
        'Sub::Quote'            => 0,
        'URI'                   => 0,
        'Hash::Flatten'         => 0,
        'Sys::Hostname'         => 0,
        'Getopt::Long'          => 0,
        'Path::Tiny'            => 0,
        'Path::Class'           => 0,
        'YAML::Syck'            => 0,
    },

    EXE_FILES => [ 'script/shepherd' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer2-Plugin-Etcd-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/hexfusion/Dancer2-Plugin-Etcd',
            bugtracker => 'https://github.com/PerlDancer/Dancer2-Plugin-Etcd/issues',
            homepage   => 'https://github.com/PerlDancer/Dancer2-Plugin-Etcd/',
            IRC        => 'irc://irc.perl.org/#dancer',
        },
    },
);
