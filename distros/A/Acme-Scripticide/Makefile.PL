use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Acme::Scripticide',
    VERSION_FROM      => 'Scripticide.pm', 
    PREREQ_PM         => { version => 0 },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'Scripticide.pm',
       AUTHOR         => 'Daniel Muey, <http://drmuey.com/cpan_contact.pl>') : ()),
);
