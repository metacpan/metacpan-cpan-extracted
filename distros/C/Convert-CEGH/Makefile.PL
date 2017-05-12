use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'Convert::CEGH',
	DISTNAME	=> 'Convert-CEGH',
	VERSION		=> "0.02",
	AUTHOR		=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "Gematria and Transliteration for Coptic, Ethiopic, Greek and Hebrew.",
	PREREQ_PM 	=> { 'Regexp::Ethiopic' => '0.10' },
	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
);
