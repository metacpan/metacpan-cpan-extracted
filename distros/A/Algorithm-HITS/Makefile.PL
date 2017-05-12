use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Algorithm-HITS',
    VERSION_FROM      => 'lib/Algorithm/HITS.pm',
    PREREQ_PM         => {
	'PDL' => '2.4',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Algorithm/HITS.pm',
       AUTHOR         => 'Yung-chung Lin <xern@cpan.org>') : ()),
);
