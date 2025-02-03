use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Convert::Number::Coptic',
	'DISTNAME'	=> 'Convert-Number-Coptic',
	'VERSION_FROM'	=> 'lib/Convert/Number/Coptic.pm', # finds $VERSION
	'AUTHOR'	=> "Daniel Yacob <dyacob\@cpan.org>",
	'ABSTRACT'	=> "Conversion for Coptic Numerals in Perl.",
	'dist'		=>	{
		'COMPRESS'        =>	"gzip -9f",
		'SUFFIX'          =>	"gz",
		'POSTOP'          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	'LICENSE'	=> 'perl',
	'MIN_PERL_VERSION' => '5.6.1'
);
