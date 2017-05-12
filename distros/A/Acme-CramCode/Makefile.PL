use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'Acme::CramCode',
    'VERSION_FROM'	=> 'CramCode.pm', 
    'PREREQ_PM'		=> {
	'Compress::Zlib' => '1.19',
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'CramCode.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
