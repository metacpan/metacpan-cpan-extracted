use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.1 2001/09/24 20:18:44 jgsmith Exp $

WriteMakefile( NAME => 'Config::Pod',
               VERSION_FROM => 'lib/Config/Pod.pm',
               dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
             );
