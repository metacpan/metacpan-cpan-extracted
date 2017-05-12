use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DBIx::Table::Dup',
    'VERSION_FROM'	=> 'Dup.pm', # finds $VERSION
    'PREREQ_PM'		=> { DBIx::DBSchema => 0.21 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Dup.pm', # retrieve abstract from module
       AUTHOR     => 'T.M. Brannon <tbone@cpan.org>') : ()),
);
