use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'DateTimeX::Fiscal::Fiscal5253',
    VERSION_FROM   => 'lib/DateTimeX/Fiscal/Fiscal5253.pm',    # finds $VERSION
    BUILD_REQUIRES => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        DateTime                => 0,
        Carp                    => 0,
        Moo                     => 0,
        MooX::StrictConstructor => 0,
    },    # e.g., Module::Name => 1.1
    MIN_PERL_VERSION => '5.8.8',
    LICENSE          => 'perl_5',
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/DateTimeX/Fiscal/Fiscal5253.pm'
            ,    # retrieve abstract from module
            AUTHOR => 'Jim Bacon <jim@nortx.com>'
          )
        : ()
    ),
);
