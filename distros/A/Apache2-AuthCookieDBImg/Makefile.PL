use 5.00;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache2::AuthCookieDBImg',
    VERSION_FROM      => 'lib/Apache2/AuthCookieDBImg.pm', # finds $VERSION
    PREREQ_PM         => {
			Apache::DBI			=> 0,
			Apache2::AuthCookie 		=> 0,
			Apache2::Const			=> 0,
			Apache2::ServerUtil		=> 0,
			Date::Calc			=> 0,
			Digest::MD5			=> 0,
	 		 }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache2/AuthCookieDBImg.pm', 
       AUTHOR         => 'Charleston Software Associates <info@charlestonsw.com>') : ()),

);
