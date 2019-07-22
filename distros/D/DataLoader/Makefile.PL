use v5.14;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'DataLoader',
    VERSION_FROM => 'lib/DataLoader.pm',
    ABSTRACT => 'Abstract data loading, auto batch and cache',
    AUTHOR => 'Richard Harris <richardjharris@gmail.com>',
    LICENSE => 'artistic_2',
    PREREQ_PM => {
        'Carp' => '0',
        'Data::Dump' => '0',
        'Mojolicious' => '0',
        'Scalar::Util' => '0',
        # For testing
        'FindBin' => '0',
        'Test::More' => '0.96',
        'Test::Deep' => '0',
        'Test::Exception' => '0',
        'AnyEvent' => '0',
    },
    test => { TESTS => 't/*.t' },
);
