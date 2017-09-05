use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Crypt::Affine',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Crypt/Affine.pm',
    ABSTRACT_FROM      => 'lib/Crypt/Affine.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'autodie'          => 0,
        'Moo'              => '2.000000',
        'namespace::clean' => '0.24',
        'Type::Tiny'       => '1.000005',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Crypt-Affine-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Crypt::Affine'         => { file => 'lib/Crypt/Affine.pm'       , version => '0.13' },
            'Crypt::Affine::Params' => { file => 'lib/Crypt/Affine/Params.pm', version => '0.13' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Crypt-Affine.git',
                web  => 'https://github.com/manwar/Crypt-Affine',
            },
        }})
     : ()
    ),
);
