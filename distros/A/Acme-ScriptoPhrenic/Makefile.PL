use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Acme::ScriptoPhrenic',
    VERSION_FROM      => 'ScriptoPhrenic.pm', 
    PREREQ_PM         => { version => 0 },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'ScriptoPhrenic.pm',
       AUTHOR         => 'Daniel Muey, <http://drmuey.com/cpan_contact.pl>') : ()),
);
