use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Acme::Snark',
    'VERSION_FROM' => 'Snark.pm', # finds $VERSION
    ($] >= 5.005 ?
	(ABSTRACT => 'What I tell you three times is true',
	AUTHOR => 'Alex Gough') : ()),
    'LICENSE' => 'perl',
);
