use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'       => 'Carlos Ramirez (carlos@quantumfx.com)',
    'NAME'	   => 'Apache::Motd',
    'VERSION_FROM' => 'Motd.pm', # finds $VERSION
    'PREREQ_PM'    => {'Apache::Cookie' => '0'}
);
