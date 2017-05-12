use ExtUtils::MakeMaker;

WriteMakefile
(
    'NAME'		=> 'Apache::Cache',
    'VERSION_FROM'	=> 'lib/Apache/Cache.pm', # finds $VERSION
    'PREREQ_PM'		=> 
    {
        Apache::SharedMem   => '0.08',
        Time::ParseDate     => '100.01_03_01',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Apache/Cache.pm',
       AUTHOR     => 'Olivier Poitrey <rs@rhapsodyk.net>') : ()),
);
