use ExtUtils::MakeMaker;
require 5.7.3;
WriteMakefile(
    'NAME'      => 'Apache::GuessCharset',
    'VERSION_FROM' => 'lib/Apache/GuessCharset.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Encode::Guess' => 0,
	'Apache::File' => 0,
	'I18N::Charset' => 1.16,
    },
);
