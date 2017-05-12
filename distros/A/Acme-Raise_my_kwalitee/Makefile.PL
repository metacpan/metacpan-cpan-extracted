use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::Raise_my_kwalitee',
    VERSION_FROM      => 'lib/Acme/Raise_my_kwalitee.pm', # finds $VERSION
    PREREQ_PM         => {DBD::Ingres=>0, Acme::Beatnik => 0.02},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Raise_my_kwalitee.pm', # retrieve abstract from module
       AUTHOR         => 'Henrik Tougaard <htoug@cpan.org>') : ()),
);
