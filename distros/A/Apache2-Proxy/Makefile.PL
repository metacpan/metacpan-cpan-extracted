#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Apache2::Proxy',
    VERSION_FROM  => 'lib/Apache2/Proxy.pm',
    PREREQ_PM     => { 'Compress::Zlib' => 0, 'Compress::Bzip2' => 0, },
    ABSTRACT_FROM => 'lib/Apache2/Proxy.pm',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>',
);
