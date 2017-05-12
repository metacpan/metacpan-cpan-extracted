use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Business::PostNL',
    VERSION_FROM => 'lib/Business/PostNL.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'Calculate Dutch (PostNL) shipping costs',
    PREREQ_PM    => {
                     'Carp'                         => 0,
                     'Class::Accessor::Fast'        => 0,
                     'List::Util'                   => 0,
                     'Test::Simple'                 => 0.44,
                     'YAML'                         => 0,
                    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/b10m/p5-Business-PostNL',
        },
    },
);
