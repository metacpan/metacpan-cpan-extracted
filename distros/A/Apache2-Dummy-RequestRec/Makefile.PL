use 5.026001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    ABSTRACT          => 'dummy request rec for testing of apache mod_perl handlers',
    NAME              => 'Apache2::Dummy::Request',
    VERSION           => '0.02',
    PREREQ_PM         => {
                            "Moops" => 0.034,
                         },
    AUTHOR            => 'jeff <jeff@lipsia.de>',
    LICENSE           => 'perl_5',
    PM                => {
                            'RequestRec.pm' => '$(INST_LIBDIR)/RequestRec.pm',
                         },
    test              => { TESTS => "t/*.t" },
);
