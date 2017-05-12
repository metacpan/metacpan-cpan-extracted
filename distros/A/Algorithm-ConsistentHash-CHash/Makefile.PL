use 5.006000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME       => 'Algorithm::ConsistentHash::CHash',
    LICENSE    => 'perl',
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url =>
                  'git@github.com:tsee/p5-Algorithm-ConsistentHash-CHash.git',
                web =>
                  'https://github.com/tsee/p5-Algorithm-ConsistentHash-CHash',
            },
        },
        'meta-spec' => { version => 2 },
    },
    VERSION_FROM => 'lib/Algorithm/ConsistentHash/CHash.pm',
    PREREQ_PM    => {
        'Test::More'        => 0,
        'ExtUtils::ParseXS' => '3',
    },
    ABSTRACT_FROM => 'lib/Algorithm/ConsistentHash/CHash.pm',
    AUTHOR        => [
        'Eric Herman <eric@freesa.org>',
        'Sawyer X <xsawyerx@cpan.org>',
        'Steffen Mueller <smueller@cpan.org>',
    ],
    DEFINE => '-std=c99',      # e.g., '-DHAVE_SOMETHING'
    INC    => '-I.',           # e.g., '-I. -I/usr/include/other'
    LIBS   => [''],            # e.g., '-lm'
    OBJECT => '$(O_FILES)',    # link all the C files too
);
