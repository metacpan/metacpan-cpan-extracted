use ExtUtils::MakeMaker;
WriteMakefile
(
          'NAME' => 'Acme::Innuendo',
          'VERSION_FROM' => 'lib/Acme/Innuendo.pm',
          'PREREQ_PM' => {
                           'Exporter::Lite' => '0',
                           'Test::More' => '0'
                         },
          'INSTALLDIRS' => 'site',
          'PL_FILES' => {}
        ),
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Rene Schickbauer <rene.schickbauer@gmail.com>') : ()),
;
