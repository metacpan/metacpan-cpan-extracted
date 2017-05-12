use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'	=> 'DCE::DFS',
    'VERSION_FROM' => 'DFS.pm',
    'LIBS'	=> ['-ldce -ldcedfs'], 
    'DEFINE'    => '-D_REENTRANT',
    'OBJECT'    => '$(BASEEXT)$(OBJ_EXT)'
);
