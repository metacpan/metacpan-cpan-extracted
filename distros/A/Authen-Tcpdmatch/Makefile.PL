use ExtUtils::MakeMaker;
WriteMakefile
(
          'LICENSE'      => 'gpl',
          'INSTALLDIRS'  => 'site',
          'NAME'         => 'Authen-Tcpdmatch',
          'VERSION_FROM' => 'lib/Authen/Tcpdmatch/Tcpdmatch.pm',
          'PL_FILES'     => {},
          'PREREQ_PM'    => {
                             'NetAddr::IP'         => '3.14',
                             'Attribute::Handlers' =>      0,
                             'Parse::RecDescent'   =>      0,
                            },
           ABSTRACT_FROM => 'lib/Authen/Tcpdmatch/Tcpdmatch.pm', 
           AUTHOR        => 'Ioannis Tambouras <ioannis@earthlink.net>',
);
