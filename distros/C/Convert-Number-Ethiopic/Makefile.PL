use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Convert::Number::Ethiopic',
	'DISTNAME'	=> 'Convert-Number-Ethiopic',
	'VERSION_FROM'	=> 'lib/Convert/Number/Ethiopic.pm', # finds $VERSION
	'AUTHOR'	=> "Daniel Yacob <dyacob\@cpan.org>",
	'ABSTRACT'	=> "Conversion For Ethiopic Numerals in Perl.",
	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	}
);
