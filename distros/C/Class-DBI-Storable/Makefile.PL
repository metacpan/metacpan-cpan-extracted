use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::DBI::Storable',
    'VERSION_FROM'	=> 'Storable.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Storable'   => '2.14',
        'Class::DBI' => 0,
		'Test::More' => 0,
		'Test::Warn' => 0,
	}, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Storable.pm', # retrieve abstract from module
       AUTHOR     => 'Brad Bowman <cpan@bereft.net>') : ()),
);

# Appended to the end of the Makefile
sub MY::postamble {
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

