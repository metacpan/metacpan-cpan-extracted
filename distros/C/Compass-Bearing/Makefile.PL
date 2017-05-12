use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'Compass::Bearing',
  VERSION_FROM  => 'lib/Compass/Bearing.pm',
  ABSTRACT_FROM => 'lib/Compass/Bearing.pm',
  PREREQ_PM     => {
                    'Geo::Functions'    => 0.03, 
                    'GD::Graph::Polar'  => 0.09, 
                    'Package::New'      => 0,
                   },
             );
