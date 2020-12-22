# -*- mode: perl; coding: us-ascii-unix -*-

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
   AUTHOR           => 'Peter John Acklam <pjacklam@gmail.com>',

   VERSION_FROM     => 'lib/Acme/Cow/Interpreter.pm',
   ABSTRACT_FROM    => 'lib/Acme/Cow/Interpreter.pm',

   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {
                           },

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                           },

   # A hash of modules that are needed to test the module but not run or build
   # it.

   'TEST_REQUIRES'      => {
                            'Test::More'   => 0.47,
                            'Test::Output' => 0,
                           },

   'LICENSE'            => 'perl_5',
   'LIBS'               => [''],        # e.g., '-lm'
   'DEFINE'             => '',          # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',          # e.g., '-I/usr/include/other'
   'SIGN'               => 1,

   'META_MERGE'         => {
       'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/pjacklam/p5-Acme-Cow-Interpreter.git',
                web  => 'https://github.com/pjacklam/p5-Acme-Cow-Interpreter',
            },
        },
    },

   dist                 => { COMPRESS => 'gzip -9f',
                             SUFFIX   => 'gz',
                           },

   # Output from various podlators.
   clean                => { FILES => 'Acme_Cow_Interpreter-* pod2htm*.tmp' },
  );
