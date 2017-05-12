#!/usr/bin/perl
# $Id: Makefile.PL,v 1.6 2002/09/10 03:30:51 rcaputo Exp $

use ExtUtils::MakeMaker;

# Touch CHANGES so it exists.
open(CHANGES, ">>CHANGES") and close CHANGES;

WriteMakefile
  ( NAME         => 'Curses::UI::POE',
    AUTHOR       => 'Scott S. McCoy (tag@cpan.org)',
    ABSTRACT     => 'A subclass that forces Curses::UI to use POE',
    VERSION_FROM => 'POE.pm',

    PM           => { 'POE.pm' => '$(INST_LIBDIR)/POE.pm' },
    PREREQ_PM    => { 
        'POE'        => 0.11,
        'Curses::UI' => 0.93,
    },
    dist         =>
    { COMPRESS   => 'gzip -9f',
      SUFFIX     => 'gz',
      PREOP      => ( 'svn log | ' .
                      'tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
                    ),
    },
  );
