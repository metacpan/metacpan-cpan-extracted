use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::Github::Webhook',
    AUTHOR           => q{Dominic Sonntag <dominic@s5g.de>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/Github/Webhook.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/Github/Webhook.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'JSON'       => 0,
    },
    PREREQ_PM => {
        'Dancer2'     => 0,
        'Digest::SHA' => 0,
    },
    TEST_REQUIRES => {
        'Test::Pod::Coverage' => 1.08,
        'Test::CheckManifest' => 0,
        'Pod::Coverage'       => 0.18,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Github-Webhook-*' },
);
