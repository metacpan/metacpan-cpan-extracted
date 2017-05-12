use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'BSD::Jail',
    'VERSION_FROM'	=> 'Jail.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Jail.pm', 
       AUTHOR     => 'Travis Boucher <tbone@tbone.ca>') : ()),
    'LIBS'		=> ['-lutil'],
    'DEFINE'		=> '', 
    'INC'		=> '', 
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
