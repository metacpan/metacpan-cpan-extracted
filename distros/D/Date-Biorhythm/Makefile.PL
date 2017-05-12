use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Date::Biorhythm',
  'VERSION_FROM' => 'lib/Date/Biorhythm.pm',    # finds $VERSION
  'PREREQ_PM'    => {
    'Date::Business'           => '1.2',
    'Date::Calc'               => 0,
    'Moose'                    => '0.11',
    'Math::Trig'               => 0,
  },
  EXE_FILES => [
    'bin/biorhythm'
  ],
);
