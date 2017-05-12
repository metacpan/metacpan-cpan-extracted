use CPAN::MakeMaker;
WriteMakefile(
	      'NAME'	=> 'Acme::Test::Weather',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => 'Test the weather conditions for a user.') : (),
	      'VERSION_FROM' => 'lib/Acme/Test/Weather.pm',
	      'PREREQ_PM'    => {
				 Sys::Hostname        => '0',
				 Socket               => '0',

				 CAIDA::NetGeoClient  => '0',
				 Geography::Countries => '0',
				 Weather::Underground => '0',

				 Test::Builder        => '0',
				 Test::More           => '0',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
