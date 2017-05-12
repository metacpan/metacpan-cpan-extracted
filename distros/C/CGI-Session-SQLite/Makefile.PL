use 5.008;
use ExtUtils::MakeMaker;
#
# $Id: Makefile.PL,v 1.2 2004/10/15 15:30:32 bmoyles Exp $
#
WriteMakefile(
    'NAME'		=> 'CGI::Session::SQLite',
    'VERSION_FROM'	=> 'SQLite.pm',
    'PREREQ_PM'		=> { CGI::Session => 0,
                         DBI => 0,
                         DBD::SQLite => 0
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SQLite.pm', # retrieve abstract from module
       AUTHOR     => 'Brian Moyles <bmoyles@gmail.com>') : ()),
);
