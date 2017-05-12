use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Apache::Session::Serialize::SOAPEnvelope',
    'VERSION_FROM' => 'lib/Apache/Session/Serialize/SOAPEnvelope.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Apache::Session => 1.54,
	SOAP::Lite => 0.55,
    },
);
