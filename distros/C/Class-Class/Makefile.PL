require 5.005;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile
  (AUTHOR => 'B. K. Oxley (binkley) at Home <binkley@bigfoot.com>',
   ABSTRACT => 'Class-oriented replacement for Class::Struct',
   PREREQ_PM => {'Class::ISA' => 0,
                 Pragmatic => 0},
   NAME => 'Class::Class',
   VERSION_FROM => 'lib/Class/Class.pm');
