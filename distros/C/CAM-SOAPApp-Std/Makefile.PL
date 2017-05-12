use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::SOAPApp::Std',
              'VERSION_FROM'	=> 'lib/CAM/SOAPApp/Std.pm',
              'PREREQ_PM'	=> {
                 'CAM::SOAPApp'             => '1.00',
                 'Test::More'               => '0.01',
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/SOAPApp/Std.pm',
                AUTHOR     => 'Clotho Advanced Media Inc., <cpan@clotho.com>') : ()),
              );
