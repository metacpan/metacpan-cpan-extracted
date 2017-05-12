use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'AxKit::XSP::Cookie',
    'VERSION_FROM' => 'Cookie.pm', # finds $VERSION
    'PREREQ_PM' => {
            'Apache::Cookie' => 0,
            'AxKit' => 1.4,
        },
);
