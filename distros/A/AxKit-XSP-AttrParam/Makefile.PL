use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'AxKit::XSP::AttrParam',
    'VERSION_FROM'  => 'AttrParam.pm', # finds $VERSION
    'PREREQ_PM'     => {
                        AxKit   => '1.3_95',
                       }, # e.g., Module::Name => 1.1
);
