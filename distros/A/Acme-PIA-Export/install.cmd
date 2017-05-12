if not exist "Makefile" goto generate
nmake clean
:generate
perl Makefile.PL
nmake
nmake install