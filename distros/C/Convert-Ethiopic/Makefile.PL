use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::dist {
	package MY; # so that "SUPER" works right
	my $inherited = shift->SUPER::dist(@_);
	$inherited =~ s/old text/new text/;
	$inherited;
	}

WriteMakefile(
    'NAME'			=> 'Convert::Ethiopic',
	'PM'			=>
	{
			'Ethiopic.pm' => '$(INST_LIBDIR)/Ethiopic.pm',
			'Ethiopic/System.pm' => '$(INST_LIBDIR)/Ethiopic/System.pm',
			'Ethiopic/Cstocs.pm' => '$(INST_LIBDIR)/Ethiopic/Cstocs.pm',
			'Ethiopic/Time.pm' => '$(INST_LIBDIR)/Ethiopic/Time.pm',
	},
	'DISTNAME'		=> 'Convert-Ethiopic',
    'VERSION_FROM'	=> 'Ethiopic.pm', # finds $VERSION
    'LIBS'			=> ['-lm -leth'], # e.g., '-lm'
    #
    #  Unfortunately isntalling the bin files require that LiveGeez be
    #  installed, and LiveGeez requires that Et be installed.  So until
    #  the demo files are smarter in the future, one must install by hand.
    #
	# 'PL_FILES'		=> { 'bin/edate.PL'		=> 'bin/edate.pl',
	# 					 'bin/enumber.PL'	=> 'bin/enumber.pl',
	# 					 'bin/estring.PL'	=> 'bin/estring.pl'
	# 				   },
	# 'EXE_FILES'		=> ['bin/edate.PL', 'bin/enumber.PL', 'bin/estring.PL'],
	'dist'			=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
);
