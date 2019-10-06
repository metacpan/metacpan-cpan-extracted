use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Compare::Directory',
    VERSION_FROM       => 'lib/Compare/Directory.pm',
    ABSTRACT_FROM      => 'lib/Compare/Directory.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Test::Excel'       => '1.35',
        'Test::Deep'        => '1.120',
        'CAM::PDF'          => '1.52',
        'File::Compare'     => '1.1003',
        'XML::SemanticDiff' => '1.0',
        'Text::PDF'         => '0.29',
        'Scalar::Util'      => '1.45',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Compare-Directory-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Compare::Directory' => { file => 'lib/Compare/Directory.pm', version => '1.26' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Compare-Directory.git',
                web  => 'https://github.com/manwar/Compare-Directory',
            },
        }})
     : ()
    ),
);
