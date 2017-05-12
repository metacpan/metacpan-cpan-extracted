use ExtUtils::MakeMaker;
WriteMakefile(
   'NAME'		=> 'CAM::XML',
   'VERSION_FROM'	=> 'lib/CAM/XML.pm',
   'PREREQ_PM'	=> {
      'XML::Parser'              => '2.30',
      'Test::More'               => '0.01',
   },
   'PL_FILES'        => {},
   ($] >= 5.005 ?
    (ABSTRACT_FROM => 'lib/CAM/XML.pm',
     AUTHOR     => 'Clotho Advanced Media Inc., <cpan@clotho.com>') : ()),
);
