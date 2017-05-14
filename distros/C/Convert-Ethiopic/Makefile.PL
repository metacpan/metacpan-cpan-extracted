
print STDERR "Using compatibility macros/routines for Perl 5.004\n"
    if ($] < 5.0045);


use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'install',
	DISTNAME		=> 'Convert-Ethiopic',
	VERSION_FROM		=> 'lib/Convert/Ethiopic.pm', # finds $VERSION
	LIBS			=> ['-lm -leth'], # e.g., '-lm'

	#
	#  Unfortunately isntalling the bin files require that LiveGeez be
	#  installed, and LiveGeez requires that Et be installed.  So until
	#  the demo files are smarter in the future, one must install by hand.
	#
	# 'PL_FILES'			=> {
	#	 'bin/edate.PL'		=> 'bin/edate.pl',
	# 	 'bin/enumber.PL'	=> 'bin/enumber.pl',
	# 	 'bin/estring.PL'	=> 'bin/estring.pl'
	# },
	# 'EXE_FILES'		=> ['bin/edate.PL', 'bin/enumber.PL', 'bin/estring.PL'],

        dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	AUTHOR          => "Daniel Yacob <Yacob\@EthiopiaOnine.Net>",
	ABSTRACT        => "Interface to the LibEth Library.",
);
