use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile( 'NAME'	       => 'Compress::PPMd',
	       'VERSION_FROM'  => 'PPMd.pm',
	       'ABSTRACT_FROM' => 'PPMd.pm',
	       'PREREQ_PM'     => { 'Test::More' => 0,
				    'ExtUtils::MakeMaker' => 6.05 },
	       'CC'            => ( $^O=~/Win32/ ? 'CL /TP' : 'g++' ),
	       ($^O=~/Win32/ ? () : (LD => 'g++') ),
	       'OBJECT'        => '$(BASEEXT)$(OBJ_EXT) Model$(OBJ_EXT)',
	       'AUTHOR'        => 'Salvador Fandiño <sfandino@yahoo.com>' );
