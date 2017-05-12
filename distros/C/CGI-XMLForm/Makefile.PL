use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CGI::XMLForm',
	'DIR'	=> [qw(Path)],
	'PREREQ_PM' => {'XML::Parser' => '2.20' },
    'VERSION_FROM' => 'XMLForm.pm', # finds $VERSION
	'dist'	=> {COMPRESS => 'gzip', 'SUFFIX' => 'gz'},
);
