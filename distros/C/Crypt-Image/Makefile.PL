use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Crypt::Image',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Crypt/Image.pm',
    ABSTRACT_FROM      => 'lib/Crypt/Image.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Math::Random'         => '0.71',
        'POSIX'                => '1.09',
        'GD::Image'            => '2.38',
        'autodie'              => 0,
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
        'Type::Tiny'           => '1.000005',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Crypt-Image-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Crypt::Image'         => { file => 'lib/Crypt/Image.pm',        version => '0.13' },
            'Crypt::Image::Axis'   => { file => 'lib/Crypt/Image/Axis.pm',   version => '0.13' },
            'Crypt::Image::Util'   => { file => 'lib/Crypt/Image/Util.pm',   version => '0.13' },
            'Crypt::Image::Params' => { file => 'lib/Crypt/Image/Params.pm', version => '0.13' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Crypt-Image.git',
                web  => 'https://github.com/manwar/Crypt-Image',
            },
        }})
     : ()
    ),
);
