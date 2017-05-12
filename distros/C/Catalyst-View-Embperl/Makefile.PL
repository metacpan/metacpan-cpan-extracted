use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::View::Embperl',
    AUTHOR    => 'Christophe Le Bars (clb@2fp.net)',
    PREREQ_PM => {
        Catalyst       => '5.5',
        Embperl        => 0,
    },
    VERSION_FROM => 'lib/Catalyst/View/Embperl.pm'
);
