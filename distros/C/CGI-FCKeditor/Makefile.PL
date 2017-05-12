use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::FCKeditor',
    VERSION_FROM      => 'lib/CGI/FCKeditor.pm',
    PREREQ_PM         => {
        'Test::More'        => '0',
    },
);
