# $Id: Makefile.PL,v 1.2 2007/02/15 23:52:08 mike Exp $

use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Biblio::EndnoteStyle',
    VERSION_FROM      => 'lib/Biblio/EndnoteStyle.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Biblio/EndnoteStyle.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@miketaylor.org.uk>') : ()),
    EXE_FILES    => [ 'bin/endnote-format' ],
);
