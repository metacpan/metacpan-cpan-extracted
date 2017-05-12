require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9vf',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'Audio::Play::MPG123',
    'EXE_FILES'	=> ['mpg123sh'],
    'VERSION_FROM' => 'MPG123.pm',
    'LIBS'	=> [''],
    'DEFINE'	=> '',
    'INC'	=> '',
);

print <<EOF;

**************************************************************************
*                                                                        *
* Audio::Play::MPG123 is now configured.                                 *
*                                                                        *
* Remember to compile the mpg123 binary that is included in the          *
* distribution in the subdirectory mpg123/                               *
*                                                                        *
* Enter "look Audio::Play::MPG123" from the CPAN prompt to get to the    *
* distribution directory.                                                *
*                                                                        *
**************************************************************************

EOF
