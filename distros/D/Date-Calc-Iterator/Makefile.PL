# $Id: Makefile.PL,v 1.1.1.1 2004/03/17 19:18:11 bronto Exp $

use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Date::Calc::Iterator',
    'VERSION_FROM'	=> 'Iterator.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Test::More'  =>  0,
			    'Date::Calc'  =>  0 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Iterator.pm', # retrieve abstract from module
       AUTHOR     => 'Marco Marongiu <bronto@cpan.org>') : ()),
);
