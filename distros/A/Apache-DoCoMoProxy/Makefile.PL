use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::DoCoMoProxy',
    'VERSION_FROM' => 'DoCoMoProxy.pm', # finds $VERSION
    'PREREQ_PM' => {
        'LWP::UserAgent'        => 1.80,
        'URI'                   => 1.15,
        'mod_perl'              => 1.21,
    },

);
