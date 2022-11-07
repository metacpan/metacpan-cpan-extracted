use ExtUtils::MakeMaker;
WriteMakefile(
  LICENSE       => 'mit',
  NAME          => 'Compass::Bearing',
  VERSION_FROM  => 'lib/Compass/Bearing.pm',
  ABSTRACT_FROM => 'lib/Compass/Bearing.pm',
  PREREQ_PM     => {
                    'Geo::Functions'    => 0.03, 
                    'GD::Graph::Polar'  => 0.09, 
                    'Package::New'      => 0,
                   },
  'META_MERGE' => {
                   'resources' => {
                     'repository' => {
                       'web' => 'https://github.com/mrdvt92/perl-Compass-Bearing.git',
                       'url' => 'git@github.com:mrdvt92/perl-Compass-Bearing.git',
                       'type' => 'git'
                     },
                     'homepage' => 'https://github.com/mrdvt92/perl-Compass-Bearing',
                     'bugtracker' => {
                       'web' => 'https://github.com/mrdvt92/perl-Compass-Bearing/issues'
                     }
                   },
                   'meta-spec' => {'version' => 2}
                  },
             );
