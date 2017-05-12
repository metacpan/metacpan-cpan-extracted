
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 2006.0215,
	'NAME'	  => 'CGI::Out',
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Buffer CGI output so that diagnositcs can be given cleanly if needed',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);

