use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Convert::Number::Roman',
	'DISTNAME'	=> 'Convert-Number-Roman',
	'VERSION_FROM'	=> 'lib/Convert/Number/Roman.pm', # finds $VERSION
	'AUTHOR'	=> "Daniel Yacob <dyacob\@cpan.org>",
	'ABSTRACT'	=> "Conversion For Roman Numerals in Perl.",
	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	}
);
