use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Apache::AppCluster::Client',
    'VERSION_FROM'	=> 'Client.pm', 
    'PREREQ_PM'		=> {
   	IO::Socket => 0,
	Time::HiRes => 0,
	POSIX => 0,
	Storable => 0,
	Carp => 0,
	Digest::MD5 => 0,
    }, 
);
