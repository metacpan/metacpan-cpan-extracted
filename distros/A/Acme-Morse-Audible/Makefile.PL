use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Acme::Morse::Audible',
    'VERSION_FROM'	=> 'Audible.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Audible.pm', # retrieve abstract from module
       AUTHOR     => 'Ido Trivizki <trivizki@bigfoot.com>') : ()),
);
