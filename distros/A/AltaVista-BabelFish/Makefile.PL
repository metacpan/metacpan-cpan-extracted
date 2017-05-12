use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'AltaVista::BabelFish',
    VERSION_FROM      => 'BabelFish.pm', 
    PREREQ_PM         => { 
                             LWP::UserAgent    => 0, 
                             Locales::Language => 0, # get_native() 
                             Class::Std        => 0,
                             Class::Std::Utils => 0,
                             version           => 0,
                             # IO::Redirect      => 0, # optional
                             CPAN              => 0, # optional
                         },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'BabelFish.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
