use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'Bio::Tools::DNAGen',
    'VERSION_FROM'	=> 'DNAGen.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'DNAGen.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
    'LIBS'		=> [''], 
    'DEFINE'		=> '', 
	
    'INC'		=> '', 
	
    
);
