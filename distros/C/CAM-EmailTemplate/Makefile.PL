use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::EmailTemplate',
              'VERSION_FROM'	=> 'lib/CAM/EmailTemplate.pm',
              'PREREQ_PM'		=> {
                 'CAM::Template' => '0.90',
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/EmailTemplate.pm',
                AUTHOR     => 'Clotho Advanced Media <cpan@clotho.com>') : ()),
              );
