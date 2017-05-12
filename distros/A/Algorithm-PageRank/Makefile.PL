use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'Algorithm::PageRank',
    'VERSION_FROM'	=> 'PageRank.pm', 
    'PREREQ_PM'		=> {
	'PDL' => '2.4',
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'PageRank.pm', 
       AUTHOR     => 'Yung-chung Lin <xern@cpan.org>') : ()),
    
);
