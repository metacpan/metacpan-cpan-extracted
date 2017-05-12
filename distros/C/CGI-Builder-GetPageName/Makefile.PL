use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'CGI::Builder::GetPageName',
    VERSION_FROM    => 'lib/CGI/Builder/GetPageName.pm',
    PREREQ_PM       => {
        'CGI::Builder'      => 0,
        'Test::Output::Tie' => 0,
        'Test::Output'      => 0,
    },
);
