use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Date::Holidays::PF',
    VERSION_FROM      => 'lib/Date/Holidays/PF.pm',
    PREREQ_PM         => {
	'Time::Local' => 0,
	'Date::Easter' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Date/Holidays/PF.pm',
       AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org>') : ()),
);
