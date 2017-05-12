use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Apache::AppCluster',
    'VERSION_FROM'	=> 'AppCluster.pm', 
    'dist' => { COMPRESS => 'gzip',
    		SUFFIX => 'gz', 
		},
    'PREREQ_PM'		=> {	
    				Time::HiRes => 0,
				Storable => 0,
				Carp => 0,
				Digest::MD5 => 0,
    			}, 
    
);
