use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::ACEProxy',
    'VERSION_FROM' => 'lib/Apache/ACEProxy.pm', # finds $VERSION
    'PREREQ_PM' => {
        'LWP::UserAgent'        => 1.80,
        'URI'                   => 1.15,
        'mod_perl'              => 1.21,
	'Convert::RACE'		=> 0.06,
	'Unicode::String'	=> 2.06,
    },
);
