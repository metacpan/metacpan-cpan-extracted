use 5.014;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'App::Diskd',
    VERSION_FROM      => 'lib/App/Diskd.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => { # module dependencies: Module::Name => version
			  'POE' => 0,
			  'POE::Session' => 0,
			  'POE::Wheel::Run' => 0,
			  'POE::Wheel::SocketFactory' => 0,
			  'POE::Filter::Line' => 0,
			  'POE::Wheel::ReadWrite' => 0,
			  'POE::Wheel::ReadLine' => 0,
			  'Sys::Hostname' => 0,
			  'Net::Nslookup' => 0,
			  'YAML::XS' => 0,
			  'IO::Socket::Multicast' => 0,
			  'Socket' => 0,
			 },
    ABSTRACT          => "An example POE-based, peer-to-peer disk finder/announcer",
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
#       ABSTRACT_FROM  => 'lib/App/Diskd.pm', # retrieve abstract from module
       AUTHOR         => 'Declan Malone <idablack@users.sorceforge.net>') : ()
    ),
    EXE_FILES          => ['bin/diskd'],
);
