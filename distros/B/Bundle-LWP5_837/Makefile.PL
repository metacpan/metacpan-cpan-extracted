#!/usr/bin/perl

BEGIN{ require 5 }
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Bundle::LWP5_837',
    AUTHOR         => 'Father Chrysostomos <org.cpan@sprout backwards>',
    VERSION_FROM   => 'lib/Bundle/LWP5_837.pm',
    ABSTRACT_FROM  => 'lib/Bundle/LWP5_837.pm',
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                TAR => 'COPYFILE_DISABLE=1 tar' },
    clean  => { FILES => 'Bundle-LWP5_837-*' },
);
