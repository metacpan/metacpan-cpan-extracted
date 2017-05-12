# -*- mode: perl; coding: us-ascii-unix -*-
#
# Author:      Peter John Acklam
# Time-stamp:  2010-05-26 13:43:22 +02:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (
   (MM->can('signature_target') ? (SIGN => 1) : ()),
   NAME             => 'Acme::Cow::Interpreter',
   AUTHOR           => 'Peter John Acklam <pjacklam@online.no>',

   VERSION_FROM     => 'lib/Acme/Cow/Interpreter.pm',
   ABSTRACT_FROM    => 'lib/Acme/Cow/Interpreter.pm',

   PREREQ_PM        => {
                        'Test::More' => 0,
                        'Test::Output' => 0,
                       },

   dist             => { COMPRESS => 'gzip -9f',
                         SUFFIX   => 'gz',
                       },

   # Output from various podlators.
   clean            => { FILES => 'Acme_Cow_Interpreter-* pod2htm*.tmp' },
  );
