require 5.6.0;
use ExtUtils::MakeMaker;
WriteMakefile
(
          'NAME' => 'Acme::AutoColor',
          'VERSION_FROM' => 'lib/Acme/AutoColor.pm',
          'PREREQ_PM' => {
                           'Graphics::ColorNames' => '0.32',
                           'Test::More' => 0
                         },
          'INSTALLDIRS' => 'site',
          'EXE_FILES' => [],
          'PL_FILES' => {}
        ),
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Rene Schickbauer <rene.schickbauer@gmail.com>') : ()),
;
