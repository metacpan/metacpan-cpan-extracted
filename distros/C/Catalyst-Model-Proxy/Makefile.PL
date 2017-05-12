use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Model::Proxy',
    AUTHOR    => 'Alex Pavlovic (alex.pavlovic@taskforce-1.com)',
    PREREQ_PM => {
        Catalyst            => '5.00',
    },
    VERSION_FROM => 'lib/Catalyst/Model/Proxy.pm'
);
