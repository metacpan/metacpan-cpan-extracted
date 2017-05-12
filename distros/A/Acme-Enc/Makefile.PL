use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Acme::Enc',
    VERSION_FROM      => 'Enc.pm',
    PREREQ_PM         => { 
                             'version'        => 0, 
                             'Crypt::OpenPGP' => 0, 
                         },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'Enc.pm',
       AUTHOR         => 'Daniel Muey, <http://drmuey.com/cpan_contact.pl>') : ()),
);
