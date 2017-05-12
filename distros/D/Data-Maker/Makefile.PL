use ExtUtils::MakeMaker;

WriteMakefile( 
        'VERSION_FROM' => 'lib/Data/Maker.pm',
        'NAME'         => 'Data::Maker',
        'PREREQ_PM' => {
          'Moose' => 0,
          'MooseX::Aliases' => 0,
          'DateTime::Event::Random' => 0,
          'Text::GenderFromName' => 0,
          'Text::Lorem' => 0,
          'Test::More' => 0,
        }
);
