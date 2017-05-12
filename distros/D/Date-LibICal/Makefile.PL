use 5.012004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Date::LibICal',
    VERSION_FROM  => 'lib/Date/LibICal.pm',
    PREREQ_PM     => {},
    TEST_REQUIRES => {
        DateTime => 0,
    },
    (
        $] >= 5.005
            ? (
                ABSTRACT_FROM  => 'lib/Date/LibICal.pm',
                AUTHOR         => q{Andreas 'ac0v' Specht  <ac0v@sys-network.de>},
            )
            : ()
    ),
    LIBS   => ['-lical'],
    DEFINE => q{},
    INC    => '-I.',
);
