use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::Config::YAML',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/Config/YAML.pm',
    PREREQ_PM         => {
        'Config::YAML' => 0,
    },
);

