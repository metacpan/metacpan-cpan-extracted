use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Business::FR::SIRET',
    VERSION_FROM      => 'lib/Business/FR/SIRET.pm',
    PREREQ_PM         => {
	'Algorithm::LUHN' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Business/FR/SIRET.pm',
       AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org>') : ()),
);
