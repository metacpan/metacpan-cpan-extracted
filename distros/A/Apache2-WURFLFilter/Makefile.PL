use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
  print << 'EOT1';
  
Mobile Apache Filter (idel@idelfuschini.it)
Documentation: http://www.idelfuschini.it/it/apache-mobile-filter-v2x.html
 
EOT1
WriteMakefile(
    NAME		=> 'Apache2::WURFLFilter',
    VERSION_FROM	=> 'lib/Apache2/WURFLFilter.pm',
    DISTNAME	=> "Apache2-WURFLFilter",
    dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},
    PREREQ_PM    => {
                     'Apache2::Filter' => 0,
                     'Apache2::RequestRec' => 0,
                     'Apache2::RequestUtil' => 0,
                     'Apache2::SubRequest' => 0,
                     'Apache2::Connection' => 0,
                     'CGI::Cookie' => 0, 
                     'APR::Table' => 0, 
                     'Apache2::Const' => 0, 
		     'Image::Resize' => 0,
		     'LWP::Simple' => 0,
		     'File::Copy' => 0,
	       	     'IO::Uncompress::Unzip'  => 0,
	       	 'Cache::Memcached'  => 0,
		     'Cache::FileBackend' => 0 		 
                     },
    AUTHOR     	=> 'Idel Fuschini (idel@idelfuschini.it)' 
   
);
