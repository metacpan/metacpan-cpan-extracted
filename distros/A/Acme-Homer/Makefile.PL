use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Acme::Homer',
    VERSION_FROM      => 'Homer.pm', 
    PREREQ_PM         => { version => 0 },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'Homer.pm',
       AUTHOR         => 'Daniel Muey, <http://drmuey.com/cpan_contact.pl>') : ()),
);
