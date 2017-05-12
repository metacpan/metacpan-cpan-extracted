use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	   => 'Apache::RequestNotes',
    'VERSION_FROM' => 'RequestNotes.pm', # finds $VERSION
    'PREREQ_PM'    => { Apache::Request => 0.31_03,
                        Apache::Cookie  => 0 },
);
