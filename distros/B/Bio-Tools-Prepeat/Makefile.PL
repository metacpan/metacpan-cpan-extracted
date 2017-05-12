use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'Bio::Tools::Prepeat',
    'VERSION_FROM'	=> 'VERSION', 
    'PREREQ_PM'		=> {
	'Cwd' => '2.06',
	'String::Random' => '0.198',
	'IO::File' => '1.09',
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Prepeat.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
    'LIBS'		=> [''], 
    'DEFINE'		=> '', 
    'INC'		=> '', 
	
    
);
