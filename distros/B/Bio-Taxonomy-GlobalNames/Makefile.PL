use 5.10.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Bio::Taxonomy::GlobalNames',
    AUTHOR =>
      q{Dimitrios - Georgios Kontopoulos <d.kontopoulos13@imperial.ac.uk>},
    VERSION_FROM       => 'lib/Bio/Taxonomy/GlobalNames.pm',
    ABSTRACT_FROM      => 'lib/Bio/Taxonomy/GlobalNames.pm',
    LICENSE            => 'perl',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.10.0,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => {
        'LWP::UserAgent'  => 6.05,
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'JSON'             => 2.90,
        'JSON::Parse'      => 0.23,
        'LWP::UserAgent'   => 6.05,
        'Moo::Lax'         => 0.12,
        'Moo'              => 1.004005,
        'REST::Client'     => 249,
        'Scalar::Readonly' => 0.03,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Bio-Taxonomy-GlobalNames-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url =>
'https://github.com/dgkontopoulos/Bio-Taxonomy-GlobalNames.git',
                web =>
                  'https://github.com/dgkontopoulos/Bio-Taxonomy-GlobalNames',
            },
        },
    },
);
