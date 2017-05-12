use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME' => "CGI::EncryptForm",
	'AUTHOR' => 'Peter Marelas <maral@phase-one.com.au>',
	'VERSION_FROM' => 'EncryptForm.pm',
	'ABSTRACT' => 'Implement trusted stateful CGI Form Data using cryptography.',
	'PREREQ_PM' => {'Storable' => 0, 'Digest::SHA1' => 0, 'Crypt::HCE_SHA' => 0}
);

