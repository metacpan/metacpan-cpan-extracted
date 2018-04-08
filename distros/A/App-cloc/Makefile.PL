use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    ABSTRACT_FROM    => 'lib/App/cloc.pm',
    VERSION_FROM     => 'lib/App/cloc.pm',
    AUTHOR           => ['G. Casati <fibo@cpan.org>', 'Al Danial <al.danial@gmail.com>'],
    NAME             => 'App::cloc',
    EXE_FILES        => ['bin/cloc'],
    LICENSE          => 'gpl_2',
    MIN_PERL_VERSION => '5.8.0',
    META_MERGE       => {
        resources => {
            homepage   => 'http://cloc.sourceforge.net',
            license    => 'https://github.com/AlDanial/cloc/blob/master/LICENSE',
            repository => 'https://github.com/AlDanial/cloc',
            bugtracker => 'https://github.com/AlDanial/cloc/issues'
        },
    },
    PREREQ_PM => {
        'Algorithm::Diff' => '1.1903',
        'Digest::MD5'     => '2.54',
        'Regexp::Common'  => '201331301',
        'Test::Compile'   => '1.2.1',
        'Test::More'      => '1.001009',
        'Test::Pod'       => '1.48'
    },
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

