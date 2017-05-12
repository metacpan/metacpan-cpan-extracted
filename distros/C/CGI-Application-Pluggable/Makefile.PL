use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::Application::Pluggable',
    VERSION_FROM      => 'lib/CGI/Application/Pluggable.pm',
    PREREQ_PM         => {
        CGI::Application => 0,
        UNIVERSAL::require => '0.10',
    },
);
