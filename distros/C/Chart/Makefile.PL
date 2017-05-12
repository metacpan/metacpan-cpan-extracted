use ExtUtils::MakeMaker;

#  make the samples directory
mkdir ('samples', 00755);

#  write the makefile
WriteMakefile ( 'NAME' => 'Chart',
		'PREREQ_PM' => { 'GD' => 2.0 },
		'dist' => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'gz' },
		'VERSION' => '2.4.10' )
