use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'      => 'Date::Discordian',
  'PREREQ_PM' => {
      'Time::Local'    => 0,
      'Test::More'     => 0,
      'Date::Leapyear' => 0,
      'Date::ICal'     => '1.54',
      'Memoize'        => 0,
  },
  'VERSION_FROM' => 'lib/Date/Discordian.pm',    # finds $VERSION
);

