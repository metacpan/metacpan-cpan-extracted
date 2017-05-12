# -*- perl -*-

BEGIN { require 5.004; }

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT     => 'Extract distribution name and version from a distribution filename',
    AUTHOR       => q[Graham Barr <gbarr@cpan.org>],
    NAME         => q[CPAN::DistnameInfo],
    PREREQ_PM    => {
      'Test::More' => 0,
    },
    VERSION_FROM => 'lib/CPAN/DistnameInfo.pm',
    (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
    (   eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
            META_MERGE => {
                resources => {    ##
                    repository => 'http://github.com/gbarr/CPAN-DistnameInfo',
                },
            }
          )
        : ()
    ),
);

