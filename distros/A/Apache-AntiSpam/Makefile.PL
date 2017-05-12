use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::AntiSpam',
    'PREREQ_PM'	=> {
	Email::Find	=> 0.04,
	HTML::Entities	=> 0,
	mod_perl	=> 1.21,
    },
    'VERSION_FROM' => 'lib/Apache/AntiSpam.pm', # finds $VERSION
);

