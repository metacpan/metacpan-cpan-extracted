#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'Data::SingletonManager',
    VERSION_FROM            => 'lib/Data/SingletonManager.pm',
    AUTHOR                  => 'Brad Fitzpatrick <brad@danga.com>',
    ABSTRACT                => 'Return/set/clear instances of singletons identified by keys in different namespaces.',

    PREREQ_PM               => {
        'Test::More' => 0,
    },
    dist                    => {
        SUFFIX                  => ".gz",
        DIST_DEFAULT            => 'all tardist',
        COMPRESS                => "gzip",
    },
);


