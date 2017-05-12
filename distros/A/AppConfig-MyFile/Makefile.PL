use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	     => 'AppConfig::MyFile',
    'VERSION_FROM'   => 'MyFile.pm', # finds $VERSION
    'PREREQ_PM'      => { 'AppConfig' => 1.52 },
    'MAN3PODS'       => { 
	# We must explicitly name AppConfig.pm et al as manifyable files.
	# MakeMaker ignores files that match  /(config|setup).*\.pm/i;
	'MyFile.pm'   
		=> '$(INST_MAN3DIR)/AppConfig::MyFile.$(MAN3EXT)',
    },
    'dist'           => { 
	'COMPRESS'   => 'gzip', 
	'SUFFIX'     => 'gz',
    },
);
    
