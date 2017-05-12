use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Class::CompoundMethods',
    VERSION_FROM => 'lib/Class/CompoundMethods.pm',
    PREREQ_PM    => {
        strict   => 0,
        vars     => 0,
        Exporter => 0,
        B        => 0
    },
    (   $] >= 5.005
        ? ( ABSTRACT_FROM => 'lib/Class/CompoundMethods.pm',
            AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>'
            )
        : ()
    ),
);
