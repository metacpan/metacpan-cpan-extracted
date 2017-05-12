# -*- perl -*-

use strict;
use warnings;

$^O eq 'darwin'
    or die "OS unsupported\n";

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'AnyEvent::Mac::Pasteboard',
    VERSION_FROM   => 'lib/AnyEvent/Mac/Pasteboard.pm', # finds $VERSION
    ABSTRACT_FROM  => 'lib/AnyEvent/Mac/Pasteboard.pm',
    AUTHOR         => 'OGATA Tetsuji <tetsuji.ogata at gmail.com>',
    PREREQ_PM      => {
        'AnyEvent'        => 0,
        'Mac::Pasteboard' => 0,
        'Scalar::Util'    => 0,
        'Time::HiRes'     => 0,
    },
    PMLIBDIRS      => ["lib"],
    META_MERGE     => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/xtetsuji/p5-AnyEvent-Mac-Pasteboard/issues',
            repository => 'git://github.com/xtetsuji/p5-AnyEvent-Mac-Pasteboard.git',
        },
    },
    LICENSE        => "perl",
    PL_FILES       => {},
    EXE_FILES      => [],
    dist           => {
        SUFFIX => 'gz',
        COMPRESS => 'gzip -9f',
    },
);
