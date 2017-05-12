# $Id: Makefile.PL,v 1.3 2003-08-13 17:09:43 bronto Exp $

use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Password::BasicCheck',
    'VERSION_FROM'	=> 'BasicCheck.pm',
    'PREREQ_PM'		=> { 'Test::More' => 0 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'BasicCheck.pm', # retrieve abstract from module
       AUTHOR     => 'Marco Marongiu <bronto@cpan.org>') : ()),
);
