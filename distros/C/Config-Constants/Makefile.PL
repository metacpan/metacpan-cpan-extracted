use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Config::Constants',
    VERSION_FROM => 'lib/Config/Constants.pm', 
    PREREQ_PM    => {
        'Test::More' => 0.47,
        'XML::SAX'   => 0.12
    }
);
