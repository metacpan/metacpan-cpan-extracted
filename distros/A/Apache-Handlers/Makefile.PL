use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.2 2002/01/07 15:30:03 jgsmith Exp $

WriteMakefile( NAME => 'Apache::Handlers',
               VERSION_FROM => 'lib/Apache/Handlers.pm',
               PREREQ_PM =>    { Perl::WhichPhase => 0.01,
                               },
               dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
             );
