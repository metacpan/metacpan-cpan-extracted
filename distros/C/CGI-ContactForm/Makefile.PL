# $Id: Makefile.PL,v 1.6 2005/02/12 01:03:24 gunnarh Exp $

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::ContactForm',
    VERSION_FROM      => 'lib/CGI/ContactForm.pm',
    PREREQ_PM         => { Mail::Sender => 0 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/CGI/ContactForm.pm',
       AUTHOR         => 'Gunnar Hjalmarsson <cpan@gunnar.cc>'
      ) : ()
    ),
);
