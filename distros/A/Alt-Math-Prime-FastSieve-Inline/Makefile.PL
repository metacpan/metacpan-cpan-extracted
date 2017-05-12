## no critic(RCS,VERSION,interpolation)
use 5.008001; use strict; use warnings; use utf8;

use lib 'inc';
use ExtUtils::MakeMaker;
use Inline::Module;

my $alt = $ENV{PERL_ALT_INSTALL} || '';
WriteMakefile(
    NAME             => 'Alt::Math::Prime::FastSieve::Inline',
    VERSION_FROM     => 'lib/Alt/Math/Prime/FastSieve/Inline.pm',
    ABSTRACT_FROM    => 'lib/Alt/Math/Prime/FastSieve/Inline.pm',
    AUTHOR           => 'David Oswald <davido [@at] cpan [d.o.t] org>',
    LICENSE          => 'artistic',
    MIN_PERL_VERSION => '5.008001',
    postamble => {
        inline => {
            module   => 'Math::Prime::FastSieve',
            stub     => 'Math::Prime::FastSieve::Inline',
            ilsm     => 'Inline::CPP',
            makestub => 1,
        },
    },
    PREREQ_PM        => {
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.04',
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.04',
        'Test::More'          => '1.001009',
    },
    META_MERGE   => {
        'meta-spec' => { version => 2 },
        prereqs     => {
            develop => {
                requires => {
                    'Inline::CPP'    => '0.69',
                    'Inline::Module' => '0.30',
                },
            },
        },
        provides => {
            'Alt::Math::Prime::FastSieve::Inline' => {
                file    => 'lib/Alt/Math/Prime/FastSieve/Inline.pm',
                version => '0.07',
            },
        },
    },
    DESTDIR => $alt ? $alt eq 'OVERWRITE' ? '' : $alt : 'no-install-alt',
);
