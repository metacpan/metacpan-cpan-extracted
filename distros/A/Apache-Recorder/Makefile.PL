use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::Recorder',
    'VERSION_FROM' => 'Recorder.pm', # finds $VERSION
    'PREREQ_PM' => {
	'CGI::Cookie'       => 1.21, #1.18 has a bug during parse()
	'Apache::URI'       => 0,
	'Storable'          => 0,
	'Apache::Constants' => 0,
    },

);
