use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'AxKit::XSP::Exception',
    'VERSION_FROM' => 'Exception.pm', # finds $VERSION
    'PREREQ_PM' => { AxKit => 1.4,
                   },
);
