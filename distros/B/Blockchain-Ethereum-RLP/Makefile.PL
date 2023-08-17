use v5.26;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Blockchain::Ethereum::RLP',
    AUTHOR           => q{Reginaldo Costa <refeco@cpan.org>},
    VERSION_FROM     => 'lib/Blockchain/Ethereum/RLP.pm',
    ABSTRACT_FROM    => 'lib/Blockchain/Ethereum/RLP.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => 'v5.26',
    EXE_FILES        => ["bin/rlp"],
    META_MERGE       => {
        'meta-spec' => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/refeco/perl-RLP.git',
                web  => 'https://github.com/refeco/perl-RLP',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.70',
    },
    TEST_REQUIRES => {},
    PREREQ_PM     => {'Object::PAD' => '0.79'},
    dist          => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {FILES => 'Blockchain-Ethereum-RLP-*'},
);

WriteMakefile(%WriteMakefileArgs);
