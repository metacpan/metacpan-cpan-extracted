use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CGI::Builder::PathInfoMagic',
    VERSION_FROM => 'lib/CGI/Builder/PathInfoMagic.pm',
    PREREQ_PM    => {
        'CGI::Builder'        => 0,
        'Test::Output'        => 0,
    },
);
