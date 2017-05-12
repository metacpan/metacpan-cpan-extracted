use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Class::WeakSingleton',
    AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>',
    ABSTRACT_FROM => 'lib/Class/WeakSingleton.pm',
    VERSION_FROM  => 'lib/Class/WeakSingleton.pm',
    PREREQ_PM     => {
        'Test::More'   => 0,
        'Scalar::Util' => 0
    },

    # This is some magic to get Build to ignore this file.
    PL_FILES => {},
);
