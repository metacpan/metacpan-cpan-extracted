use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Catalyst::Plugin::EnvironmentDetector',
    VERSION_FROM      => 'lib/Catalyst/Plugin/EnvironmentDetector.pm',
    PREREQ_PM         => { Sys::Hostname => 0 },
    AUTHOR            => 'Kevin L. Kane <kkane@cpan.org>',
);
