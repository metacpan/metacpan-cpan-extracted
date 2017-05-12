require 5.005;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile
  (AUTHOR => 'B. K. Oxley (binkley) at Home <binkley@bigfoot.com>',
   NAME => 'CGI::PrintWrapper',
   PREREQ_PM =>
   {
    Carp => 0,
    CGI => 2
   },
   VERSION_FROM => 'lib/CGI/PrintWrapper.pm');
