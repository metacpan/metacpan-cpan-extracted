use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache2::AuthenNTLM',
    'VERSION_FROM' => 'AuthenNTLM.pm', # finds $VERSION
	'AUTHOR' => 'Gerald Richter <richter@dev.ecos.de>',
	'ABSTRACT' => 'Perform Microsoft NTLM and Basic User Authentication',
    'PREREQ_PM'    => { 'MIME::Base64' => 0 },

);

