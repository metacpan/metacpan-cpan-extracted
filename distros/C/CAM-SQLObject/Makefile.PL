use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::SQLObject',
              'VERSION_FROM'	=> 'lib/CAM/SQLObject.pm',
              'PREREQ_PM'		=> {
                 'CAM::SQLManager'          => '1.00',
                 'Test::More'               => '0.01', # tested on 0.47
              },
              'PL_FILES' => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/SQLObject.pm',
                AUTHOR        => 'Clotho Advanced Media Inc. <cpan@clotho.com>') : ()),
              );
