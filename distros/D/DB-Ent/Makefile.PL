use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "DB::Ent",
    VERSION_FROM    => "Ent.pm",
    $] < 5.005 ? () : (
        AUTHOR          => 'Erick Calder <ecalder@cpan.org>',
        ABSTRACT_FROM   => 'Ent.pm',
        ),
    PREREQ_PM       => {
        DBI => 0
        },
    );
