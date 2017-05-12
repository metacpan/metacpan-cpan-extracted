use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Astro::SpaceElevator',
              AUTHOR       => 'Daniel Brooks <db48x@yahoo.com>',
              VERSION_FROM => 'Astro/SpaceElevator.pm',
              LICENSE      => 'perl',
              ABSTRACT     => 'Model a Space Elevator',
              dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              PREREQ_PM    => {
                  'Astro::Coord::ECI' => 0,
                  'Math::MatrixReal'  => 2.02,
              },);
