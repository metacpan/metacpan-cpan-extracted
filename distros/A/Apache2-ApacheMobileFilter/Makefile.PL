use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
  print << 'EOT1';
  
Apache Mobile Filter (idel@idelfuschini.it)
Documentation: http://wiki.apachemobilefilter.org
DemoSite: http://www.apachemobilefilter.org

To try quickly the AMF add on httpd.conf this few rows:


PerlSetEnv AMFMobileHome /home/AMF
PerlSetEnv WURFLNetDownload true
PerlSetEnv DownloadWurflURL http://downloads.sourceforge.net/wurfl/wurfl-latest.zip
PerlSetEnv CacheDirectoryStore /tmp
PerlTransHandler +Apache2::AMFWURFLFilter


Note:
Download Cache::Memcached library if you want use memcached (http://memcached.org)
Download Cache::Cache library if you want use filesystem for caching
In this moment AMFDeviceMonitor is only for filesystem cache


EOT1
WriteMakefile(
    NAME		=> 'Apache Mobile Filter Suite',
    VERSION_FROM	=> 'lib/Apache2/AMFWURFLFilter.pm',
    DISTNAME	=> "Apache2-ApacheMobileFilter",
    dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},
    PREREQ_PM    => {
                     'POSIX' => 0,
                     'Apache2::Filter' => 0,
                     'Apache2::RequestRec' => 0,
                     'Apache2::RequestUtil' => 0,
                     'Apache2::SubRequest' => 0,
                     'Apache2::Connection' => 0,
                     'CGI::Cookie' => 0, 
                     'APR::Table' => 0, 
                     'Apache2::Const' => 0, 
		     'Image::Resize' => 0,
                     'Image::Scale' => 0,
                     'Imager' => 0,
		     'LWP::Simple' => 0,
		     'File::Copy' => 0,
	       	     'IO::Uncompress::Unzip'  => 0,
                     'IO::Uncompress::Gunzip' => 0,
                     'Cache::Memcached'  => "1.27",
		     'Cache::FileBackend' => 0,
                     'LWP::Protocol::https' => 0,
                     'Digest::MD5' => 0
                     },
    AUTHOR     	=> 'Idel Fuschini (idel@idelfuschini.it)' 
   
);
