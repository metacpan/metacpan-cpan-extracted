use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Acme::Spork',
    VERSION_FROM      => 'lib/Acme/Spork.pm', 
    PREREQ_PM         => {
       'Proc::Daemon' => 0,
       'version'      => 0,
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'lib/Acme/Spork.pm', 
       AUTHOR         => 'Daniel Muey, L<http://drmuey.com/cpan_contact.pl>') : ()),
);
