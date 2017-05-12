use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Catalyst::Plugin::I18N::DBIC',
    AUTHOR          => 'Ian Docherty (cpan@iandocherty.com)',
    PREREQ_PM => {
        'Catalyst'                  => '2.99',
        'Catalyst::Plugin::I18N'    => '0',
        'Catalyst::Model::DBIC'     => '0',
    },
    VERSION_FROM    => 'DBIC.pm',
    ABSTRACT        => 'Obtain locale text from database',
);
