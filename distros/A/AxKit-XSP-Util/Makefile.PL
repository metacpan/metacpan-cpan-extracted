use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'AxKit::XSP::Util',
    'VERSION_FROM' => 'Util.pm', # finds $VERSION
    'PREREQ_PM' => {
            AxKit => 1.5,
            HTTP::GHTTP => 1.0,
            Time::Piece => 1.0,
            Apache::File => 0,
            XML::LibXML => 1.31,
        },
);
