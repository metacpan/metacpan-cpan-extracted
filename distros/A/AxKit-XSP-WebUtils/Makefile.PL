use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'AxKit::XSP::WebUtils',
    'VERSION_FROM' => 'WebUtils.pm', # finds $VERSION
    'PREREQ_PM' => { AxKit => 1.4 },
);
