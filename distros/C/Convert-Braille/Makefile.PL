use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'Convert::Braille',
	DISTNAME	=> 'Convert-Braille',
	VERSION_FROM	=> 'lib/Convert/Braille.pm', # finds $VERSION
	AUTHOR		=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "Conversion between Braille encodings.",
	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	}
);
