#---------------------------------------------------------
#
# Portions Copyright (c) 1994,1995,1996,1997 Tim Bunce
# Portions Copyright (c) 1997                Göran Thyni
#
#---------------------------------------------------------

use ExtUtils::MakeMaker;
use Config;
use strict;


WriteMakefile (
    'NAME'         => 'DBD::Informix4',
    'VERSION_FROM' => 'Informix4.pm',
    'LIBS'	   => ["-L$ENV{INFORMIXDIR}/lib -lsql4 -lm -lc"],
    'INC'	   =>  "-I$ENV{INFORMIXDIR}/incl -I$Config{archlib}/DBI -I$Config{sitearch}/auto/DBI",
    'OBJECT'       => 'Informix4$(OBJ_EXT) dbdimp$(OBJ_EXT)',
);

1;

# EOF
