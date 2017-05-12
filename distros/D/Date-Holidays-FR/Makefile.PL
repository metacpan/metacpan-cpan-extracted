use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Date::Holidays::FR',
    VERSION_FROM      => 'lib/Date/Holidays/FR.pm',
    PREREQ_PM         => {
	'Time::Local' => 0,
	'Date::Easter' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Date/Holidays/FR.pm',
       AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org>') : ()),
);
