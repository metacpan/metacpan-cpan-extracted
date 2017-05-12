use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Catalyst::Plugin::Account::AutoDiscovery',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Account/AutoDiscovery.pm',
    ABSTRACT_FROM     => 'lib/Catalyst/Plugin/Account/AutoDiscovery.pm',
    PREREQ_PM         => {
        Catalyst => '5.30',
    },
    AUTHOR => 'Daisuke Murase <typester@cpan.org>',
);
