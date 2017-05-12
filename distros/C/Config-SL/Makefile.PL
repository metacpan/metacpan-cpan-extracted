#!/usr/bin/env perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Config-SL',
    VERSION_FROM => 'lib/Config/SL.pm',
    PREREQ_PM    => { 'Config::ApacheFormat' => 1.2, },
    ABSTRACT     => 'Configuration abstraction for SL libraries',
    AUTHOR       => 'Fred Moyer <fred@slwifi.com>',
);
1;
