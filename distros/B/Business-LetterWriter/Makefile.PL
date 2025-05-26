use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Business::LetterWriter',
	VERSION_FROM => 'lib/Business/LetterWriter.pm',
	PREREQ_PM    => {
		'JSON'       => '4.10',
		'OpenAPI::Client::OpenAI' => '0.21',
		'Archive::Zip' => '1.68',
		'XML::Twig' => '3.53',
	},
	AUTHOR       => 'Lubell Yamamoto <lubell@cpan.org>',
	ABSTRACT     => 'Some basic functionality Business::LetterWriter',
);
