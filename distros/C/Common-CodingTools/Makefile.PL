use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;

print <<'LOGO';
[40m[38:2:102:255:0m   ___                          _ _ ___         _ _          _____         _     [0m
[40m[38:2:102:255:0m  / __|___ _ __  _ __  ___ _ _ (_|_) __|___  __| (_)_ _  __ |_   _|__  ___| |___ [0m
[40m[38:2:102:255:0m | (__/ _ \ '  \| '  \/ _ \ ' \ _ | (__/ _ \/ _` | | ' \/ _` || |/ _ \/ _ \ (_-< [0m
[40m[38:2:102:255:0m  \___\___/_|_|_|_|_|_\___/_||_(_|_)___\___/\__,_|_|_||_\__, ||_|\___/\___/_/__/ [0m
[40m[38:2:102:255:0m                                                        |___/                    [0m
[40m[38:2:102:255:0m                                                                                 [0m
LOGO

if (WriteMakefile(
    NAME               => 'Common::CodingTools',
    AUTHOR             => q{Richard Kelsch <rich@rk-internet.com>},
    VERSION_FROM       => 'lib/Common/CodingTools.pm',
    ABSTRACT_FROM      => 'lib/Common/CodingTools.pm',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.008000,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'  => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.44,
    },
    PREREQ_PM      => {
        'List::Util'     => 1.41,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Common-CodingTools-*'},
)) {
    exit(0);
}

exit(1);
