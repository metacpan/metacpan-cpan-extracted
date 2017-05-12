use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Calendar::CSA',
    'VERSION_FROM' => 'CSA.pm',
    'LIBS'	=> ['-L/usr/dt/lib -lcsa -lDtSvc', '-L/usr/dt/lib -lcsa'],   	
    # Or, use this line if your CSA installation doesn't need DtSvc
    #'LIBS'	=> ['-L/usr/dt/lib -lcsa'],   	
    'DEFINE'	=> '',     
    'INC'	=> '-I/usr/dt/include',     
    # 'OPTIMIZE'	=> '-g'
    'OBJECT'	=> 'CSA.o CsaUtils.o',
);
