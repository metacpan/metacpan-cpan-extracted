use v5.26;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Blockchain::Ethereum::ABI',
    AUTHOR           => q{Reginaldo Costa <refeco@cpan.org>},
    VERSION_FROM     => 'lib/Blockchain/Ethereum/ABI.pm',
    ABSTRACT_FROM    => 'lib/Blockchain/Ethereum/ABI.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => 'v5.26',
    META_MERGE       => {
        'meta-spec' => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/refeco/perl-ABI.git',
                web  => 'https://github.com/refeco/perl-ABI',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.70',
    },
    TEST_REQUIRES => {
        'Test::Fatal' => '0.016',
    },
    PREREQ_PM => {
        'Object::Pad'              => '0.79',
        'Crypt::Digest::Keccak256' => '0.078',
        'Math::BigInt'             => '1.999811',
        'Scalar::Util'             => '1.63',
        'Module::Load'             => '0.36',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {FILES => 'Blockchain-Ethereum-ABI-*'},
);

WriteMakefile(%WriteMakefileArgs);
