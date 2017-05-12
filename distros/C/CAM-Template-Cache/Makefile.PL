use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::Template::Cache',
              'VERSION_FROM'	=> 'lib/CAM/Template/Cache.pm',
              'PREREQ_PM'		=> {
                 'CAM::Template'            => '0.90',
                 'DBI'                      => '1.00', # tested on 1.201
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/Template/Cache.pm',
                AUTHOR     => 'Clotho Advanced Media <cpan@clotho.com>') : ()),
              );
