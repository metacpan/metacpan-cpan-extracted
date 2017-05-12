use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Application::Pipeline',
    VERSION_FROM => 'lib/Application/Pipeline.pm',
    AUTHOR       => 'Stephen Howard <howars@alum.rpi.edu>',
    ABSTRACT     => 'Framework for building applications that provides for managing plugins and application phases',
);

