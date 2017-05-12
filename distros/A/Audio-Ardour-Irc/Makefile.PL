use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Audio::Ardour::Irc',
    VERSION_FROM      => 'lib/Audio/Ardour/Irc.pm',
    PREREQ_PM         => { 
                           'Net::LibLO' => 0.06,
                           'File::HomeDir' => '0.67',
                         }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'lib/Audio/Ardour/Irc.pm', 
       AUTHOR         => 'Noel Darlow <cpan@aperiplus.co.uk>') : ()),
);
