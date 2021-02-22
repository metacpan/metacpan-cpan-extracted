use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Crypt::PBE',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/Crypt/PBE.pm',
    ABSTRACT_FROM      => 'lib/Crypt/PBE.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => ['bin/pkcs5-tool'],
    MIN_PERL_VERSION   => 5.008,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Crypt::CBC'          => '0',
        'Crypt::DES'          => '0',
        'Digest::MD2'         => '0',
        'Digest::MD5'         => '0',
        'Digest::SHA'         => '0',
        'Crypt::OpenSSL::AES' => '0',
        'Term::ReadKey'       => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Crypt-PBE',
                web  => 'https://github.com/giterlizzi/perl-Crypt-PBE'
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Crypt-PBE-*' },
);
