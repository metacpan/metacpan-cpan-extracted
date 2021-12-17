use 5.026001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    ABSTRACT          => 'dummy request rec for testing of apache mod_perl handlers',
    NAME              => 'Apache2::Dummy::Request',
    VERSION           => '0.03',
    PREREQ_PM         => {
                            "Moops" => "0.034",
                            "CGI" => "4.38",
                            "Apache2::Const" => "0.009",
                            "APR::Table" => "0.009",
                            "APR::Pool" => "0.009",
                            "Data::Compare" => "1.27",
                            "Data::Printer" => "0.40",
                            "Test::More" => "1.302181",
                            "Test::Output" => "1.031",
                            "DateTime" => "1.51",
                         },
    AUTHOR            => 'jeff <jeff@lipsia.de>',
    LICENSE           => 'perl_5',
    PM                => {
                            'RequestRec.pm' => '$(INST_LIBDIR)/RequestRec.pm',
                         },
    test              => { TESTS => "t/*.t" },
);
