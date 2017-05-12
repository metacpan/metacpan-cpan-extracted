use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Lazy',
    VERSION_FROM      => 'lib/CGI/Lazy.pm', # finds $VERSION
    PREREQ_PM         => {
    			'HTML::Template'	=> 2.9,
			'JSON'			=> 2.07,
			'DBI'			=> 1.5,
			'JavaScript::Minifier'	=> 1.05,
			'Tie::IxHash'		=> 1.21,
			'Digest::MD5'		=> 2.3,
			'Time::HiRes'		=> 1.86,
    			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 	'Simple webdev framework for cgi applications, especially web frontends to databases.', 
       AUTHOR         => 'Nik Ogura <nik.ogura@gmail.com>') : ()),
);
