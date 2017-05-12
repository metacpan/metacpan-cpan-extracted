use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::Clickable',
    'VERSION_FROM' => 'lib/Apache/Clickable.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Apache::Filter' => 0,
	'Email::Find' => 0.06,
	'URI::Find' => 0,
	'HTML::Parser' => 0,
    },
);
