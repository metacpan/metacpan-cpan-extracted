use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Apache::Session::NoSQL',
    VERSION_FROM => 'lib/Apache/Session/NoSQL.pm',    # finds $VERSION
    META_MERGE   => {
        'recommends' => {
            'Net::Cassandra' => 0,
            'Redis'          => 0,
        },
    },
    PREREQ_PM => { 'Apache::Session' => 0, },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Apache/Session/NoSQL.pm',    # retrieve abstract from module
            AUTHOR => 'Thomas Chemineau <thomas.chemineau@gmail.com>'
          )
        : ()
    ),
);
