use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::View::TT::Layout',
    AUTHOR    => 'Chunzi <chunzi@chunzi.org>',
    PREREQ_PM => {
        Catalyst     => '5.30',
    },
    VERSION_FROM => 'lib/Catalyst/View/TT/Layout.pm'
);
