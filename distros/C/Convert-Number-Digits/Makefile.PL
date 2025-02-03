use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Convert::Number::Digits',
	'DISTNAME'	=> 'Convert-Number-Digits',
	'VERSION_FROM'	=> 'lib/Convert/Number/Digits.pm', # finds $VERSION
	'AUTHOR'	=> "Daniel Yacob <dyacob\@cpan.org>",
	'ABSTRACT'	=> "Convert Digits Between the Scripts of Unicode.",
	'dist'		=>	{
		'COMPRESS'        =>	"gzip -9f",
		'SUFFIX'          =>	"gz",
		'POSTOP'          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	'LICENSE'	=> 'perl',
	'MIN_PERL_VERSION' => '5.6.1'
);
