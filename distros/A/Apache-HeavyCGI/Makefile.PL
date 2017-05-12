use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print qq{

========================= W A R N I N G =========================
========================= W A R N I N G =========================
========================= W A R N I N G =========================

    This software is legacy code and no longer in development.

                         Use at own risk.

                         Read the README.

========================= W A R N I N G =========================
========================= W A R N I N G =========================
========================= W A R N I N G =========================

};

sleep 10;

WriteMakefile(
	      'NAME'	=> 'Apache::HeavyCGI',
	      'VERSION_FROM' => 'lib/Apache/HeavyCGI.pm', # finds $VERSION
);

sub MY::postamble {
  q{
the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)

release ::
	/usr/bin/perl -I../../CPAN/SVN/release-lib -S release $(DISTVNAME).tar$(SUFFIX)
	$(CP) $(DISTVNAME)/META.yml  ./META.yml
	rm -rf $(DISTVNAME)
	svn cp -m 'This is $(VERSION)' https://franz.ak.mind.de/public-svn/Apache-HeavyCGI/trunk https://franz.ak.mind.de/public-svn/Apache-HeavyCGI/tags/$(VERSION)

}
}
