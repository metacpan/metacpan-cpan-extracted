use v5.26;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Blockchain::Ethereum::Transaction',
    AUTHOR           => q{Reginaldo Costa <refeco@cpan.org>},
    VERSION_FROM     => 'lib/Blockchain/Ethereum/Transaction.pm',
    ABSTRACT_FROM    => 'lib/Blockchain/Ethereum/Transaction.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => 'v5.26',
    EXE_FILES        => ["bin/ethereum-raw-tx"],
    META_MERGE       => {
        'meta-spec' => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/refeco/perl-ethereum-transaction.git',
                web  => 'https://github.com/refeco/perl-ethereum-transaction',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.70',
    },
    TEST_REQUIRES => {
        'Blockchain::Ethereum::Keystore::Key' => '0.002',
    },
    PREREQ_PM => {
        'Blockchain::Ethereum::RLP' => '0.006',
        'Object::Pad'               => '0.79',
        'Digest::Keccak'            => '0.05',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {FILES => 'Blockchain-Ethereum-Transaction-*'},
);

WriteMakefile(%WriteMakefileArgs);
