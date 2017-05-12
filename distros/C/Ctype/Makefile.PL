use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Ctype',
    'VERSION_FROM'	=> 'Ctype.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ? 
      (ABSTRACT_FROM => 'Ctype.pm',
       AUTHOR     => 'Samuel Lauber <sam124@operamail.com>') : ()),
    'LIBS'		=> [''],
    'DEFINE'		=> '',
    'INC'		=> '',
);
