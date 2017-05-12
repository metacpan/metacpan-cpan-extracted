use ExtUtils::MakeMaker;

WriteMakefile
(
    'NAME'		=> 'Apache::SharedMem',
    'VERSION_FROM'	=> 'lib/Apache/SharedMem.pm', # finds $VERSION
    'PREREQ_PM'		=> 
    {
        IPC::ShareLite  => '0.06',
        IPC::SysV       => '1.03',
        Storable        => '1.006',
        Data::Dumper    => '2.101',
    },
    EXE_FILES           => [grep(-f $_ && -x _, glob('./bin/*'))],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Apache/SharedMem.pm',
       AUTHOR     => 'Olivier Poitrey <rs@rhapsodyk.net>') : ()),
);
