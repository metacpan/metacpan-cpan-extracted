use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'CSV::Template',
    VERSION_FROM => 'lib/CSV/Template.pm', 
    PREREQ_PM    => {
        'Test::More'     => 0.47,
        'HTML::Template' => 2.0
    }
);
