use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'AutoSession',
    'VERSION_FROM'	=> 'lib/AutoSession.pm',
    'PREREQ_PM'		=> { "Storable" => 2.0 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/AutoSession.pm',
       AUTHOR     => 'Graciliano M. P. <gm@virtuasites.com.br>') : ()),
);

