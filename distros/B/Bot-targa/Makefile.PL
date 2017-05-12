use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    ABSTRACT_FROM    => 'lib/Bot/targa.pm',
    VERSION_FROM     => 'lib/Bot/targa.pm',
    AUTHOR           => 'G. Casati <fibo@cpan.org>',
    NAME             => 'Bot::targa',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.12.0',
    META_MERGE       => {
        resources => {
            homepage   => 'https://metacpan.org/pod/Bot::targa',
            license    => 'http://g14n.info/artistic-license',
            repository => 'https://github.com/fibo/Bot-targa-pm',
            bugtracker => 'https://github.com/fibo/Bot-targa-pm/issues'
        },
    },
    PREREQ_PM => {
        'Bot::BasicBot'    => '0.89',
        'Config::IniFiles' => '2.88',
        'JSON::XS'         => '3.01',
        'List::Util'       => '1.27',
        'LWP'              => '6.15'
    },
    EXE_FILES      => ['bin/bottarga'],
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64'
    },
    test          => { TESTS => 't/*.t' },
    TEST_REQUIRES => {
        'Test::Compile' => '1.2.1',
        'Test::More'    => '1.001009',
        'Test::Pod'     => '1.48'
    }
);
