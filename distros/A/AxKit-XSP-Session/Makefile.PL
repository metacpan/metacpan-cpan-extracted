use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'AxKit::XSP::Session',
    'VERSION_FROM' => 'lib/AxKit/XSP/Session.pm', # finds $VERSION
    'PREREQ_PM'    => {Apache::Session::Flex => 0},
);
