#!/usr/bin/perl

use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Password::Check::JPassword',
    VERSION_FROM      => 'lib/Data/Password/Check/JPassword.pm', # finds $VERSION
    BUILD_REQUIRES         => {
            'Data::Dump' => 1
        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Password/Check/JPassword.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Gwyn < gwyn -AT- cpan.org >') : ()),
);
