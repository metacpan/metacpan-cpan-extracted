# $Id: Makefile.PL,v 1.1.1.1 2005/03/31 15:21:01 gunnarh Exp $

use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'CGI::UploadEasy',
    VERSION_FROM   => 'UploadEasy.pm',
    PREREQ_PM      => { CGI => 2.76, File::Spec => 0 },
    ABSTRACT_FROM  => 'UploadEasy.pm',
    AUTHOR         => 'Gunnar Hjalmarsson <cpan@gunnar.cc>',
);

