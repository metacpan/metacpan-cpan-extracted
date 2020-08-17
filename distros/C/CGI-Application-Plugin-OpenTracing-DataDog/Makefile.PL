use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'CGI::Application::Plugin::OpenTracing::DataDog',
    'VERSION_FROM'  => 'lib/CGI/Application/Plugin/OpenTracing/DataDog.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t',
    },
);
