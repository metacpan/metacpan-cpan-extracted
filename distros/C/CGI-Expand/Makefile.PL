use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

BEGIN { 
    *MY::postamble = \&postamble if $^O =~ /^linux/i;
}

WriteMakefile(
    'NAME'		=> 'CGI::Expand',
    'VERSION_FROM'	=> 'Expand.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Test::Exception' => 0,
		'Test::More' => 0,
	}, # e.g., Module::Name => 1.1
    LICENSE => 'perl',

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Expand.pm', # retrieve abstract from module
       AUTHOR     => 'Brad Bowman <cgi-expand@bereft.net>') : ()),

);

# Appended to the end of the Makefile for linux (debian) only
sub postamble {
    return <<'POSTAMBLE';
DEBVNAME = $(shell $(PERLRUN) -le 'print lc(shift)' $(DISTVNAME))
deb : debdir
	-cd $(DEBVNAME) && debuild -us -uc

debdir : distdir
	$(RM_RF) $(DEBVNAME)
	$(MV) $(DISTVNAME) $(DEBVNAME)
	$(CP) -r debian $(DEBVNAME)

POSTAMBLE
}   

