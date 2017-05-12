use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Apache::Session::LDAP',
    VERSION_FROM => 'lib/Apache/Session/LDAP.pm',    # finds $VERSION
    PREREQ_PM    => {
        'Net::LDAP'       => 0,
        'Apache::Session' => 0,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Apache/Session/LDAP.pm',    # retrieve abstract from module
            AUTHOR => 'Xavier Guimard <guimard@>'
          )
        : ()
    ),
);
