use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'AxKit::XSP::MD5',
    'VERSION_FROM'  => 'MD5.pm',
    'PREREQ_PM'     => {
                        AxKit       => '1.4',
                        Digest::MD5 => '0',
                       },
);
