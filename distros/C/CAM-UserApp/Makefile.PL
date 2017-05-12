use ExtUtils::MakeMaker;
WriteMakefile(
              NAME            => 'CAM::UserApp',
              VERSION_FROM    => 'lib/CAM/UserApp.pm',
              PREREQ_PM       => {
                 'CAM::App'        => '1.00',
                 'CAM::Session'    => '1.00',
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/UserApp.pm',
                AUTHOR        => 'Clotho Advanced Media Inc. <cpan@clotho.com>') : ()),
              );
