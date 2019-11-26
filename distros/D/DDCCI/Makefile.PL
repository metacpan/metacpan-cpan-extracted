use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME				=> 'DDCCI',
	VERSION_FROM			=> 'lib/DDCCI.pm',
	PREREQ_PM			=> { 
		'Test::More' 		=> 0, 
		'Exporter' 		=> '5.57',
	},
	ABSTRACT_FROM 			=> 'lib/DDCCI.pm',
	AUTHOR				=> 'R.Scussat - DSP LABS Srl',
	LIBS				=> [''],
	DEFINE				=> '',
	INC				=> '-I.',
	OBJECT				=> '$(O_FILES)',
);
