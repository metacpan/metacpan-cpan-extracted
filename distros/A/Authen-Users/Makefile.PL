use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Authen::Users',
    VERSION_FROM => 'lib/Authen/Users.pm', # finds $VERSION
    AUTHOR       => 'William Hererra (whererra@skylightview.com)',
    ABSTRACT     => 'DBI/SQL based password authentication.',
    PREREQ_PM    => { DBI => 0, Digest::SHA => 0, Test::More => 0 },
    LICENSE      => 'perl',
);
