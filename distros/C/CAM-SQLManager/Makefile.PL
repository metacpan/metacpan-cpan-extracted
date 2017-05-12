use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::SQLManager',
              'VERSION_FROM'	=> 'lib/CAM/SQLManager.pm',
              'PREREQ_PM'		=> {
                 'CAM::XML'   => '1.00', # tested on 1.03
                 'DBI'        => 1.0,    # tested on 1.201, 1.38
                 'CGI'        => 2.0,    # tested on 2.80, 3.00
                 'File::Spec' => 0,      # tested on 0.86
                 'Test::More' => 0.01,   # tested on 0.47
              },
              'PL_FILES' => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/SQLManager.pm',
                AUTHOR        => 'Clotho Advanced Media Inc. <cpan@clotho.com>') : ()),
              );
