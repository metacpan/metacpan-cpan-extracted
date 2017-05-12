use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Linux
WriteMakefile(
    'NAME'	=> 'Cdk',
    'VERSION'	=> '4.9.1',
    'LIBS'	=> ['-L/home/glovem/local/lib -lcdk -lcurses'],
    'DEFINE'	=> '-DNCURSES -DCOLOR -DCDK_PERL_EXT',
    'INC'	=> '-I/usr/include/ncurses -I/home/glovem/local/include',
    'clean'	=> {FILES => 'Makefile.old'},
);

# Solaris
#WriteMakefile(
#   'NAME'	=> 'Cdk',
#   'VERSION'	=> '4.8',
#   'LIBS'	=> ['-L/usr/ccs/lib -L/home/mikeg/cdk -lcdk -lcurses'],
#   'DEFINE'	=> '-DCOLOR',
#   'INC'	=> '-I/home/mikeg/cdk',	
#   'clean'	=> {FILES => 'Makefile.old'},
#);
