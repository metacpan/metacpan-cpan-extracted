use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;

my $Top = 'DBIx';
my $Mod = 'TableHash';

WriteMakefile(
			  NAME			=> "${Top}::${Mod}",
			  DISTNAME		=> "${Top}-${Mod}",
			  VERSION_FROM	=> "$Mod.pm",
			  ABSTRACT_FROM	=> "$Mod.pm",
			  PREREQ_PM		=> {
				  'DBI'				=> 0, 
				  ## 'Carp'			=> 0, 
				  ## 'Data::Dumper'	=> 0,
			  },
			  PMLIBDIRS		=> ["$Mod"],
			  clean			=> {FILES => ".AppleDouble test/.AppleDouble test/cache/* test/cache/ test/*.out* *.bak $Mod.html"},
			  );

## This creates *.html from *.pm and does some cleanup by calling
## fix_html.perl (which is so-named because if it were called
## fix_html.pl it would get grabbed and installed by MakeMaker).

## Also creates the README as the text-format perldoc output from the
## pod in the main module's source file.

sub MY::htmlifypods
{
	"	
htmlifypods::
	pod2html --noindex --css=/stylesheet/ --title=$Top::$Mod --infile=$Mod.pm --outfile=$Mod.html
	perl fix_html.perl $Mod.html

	pod2text $Mod.pm > README

";
};
