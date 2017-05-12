use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache2::OneTimeDownload',
    'VERSION_FROM'	=> 'OneTimeDownload.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
				'Digest::MD5' => 0.01,
				'Test::More' => 0.01,
				MLDBM => 0.01,
				'Apache2::SubRequest' => 0.0,
				'Apache2::Const' => 0.0,
				'APR::Table' => 0.0,
				'Apache2::RequestRec' => 0.0,
				'Apache2::RequestIO' => 0.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'OneTimeDownload.pm', # retrieve abstract from module
       AUTHOR     => 'Stephan Jauernick <stephan@stejau.de>') : ()),
);
