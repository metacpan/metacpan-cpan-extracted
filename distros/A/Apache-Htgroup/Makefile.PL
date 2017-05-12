use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	     => 'Apache::Htgroup',
    VERSION_FROM => 'lib/Apache/Htgroup.pm', # finds $VERSION
    AUTHOR       => 'Rich Bowen (rbowen@rcbowen.com)',
    ABSTRACT     => 'Manage Apache htgroup files',
    'realclean'  => {
        FILES    => 'ChangeLog.bak'
    },
);

sub MY::postamble {
    package MY;
    "\ndocs: all\n" .
    "\tcvs2cl -r -b -t\n".
    "\tpod2text lib/Apache/Htgroup.pm > README\n"
}

