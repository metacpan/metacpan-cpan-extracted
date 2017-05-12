use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::MiniFramework',
    VERSION_FROM      => 'lib/CGI/MiniFramework.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More' => '0.47',
    },
);
