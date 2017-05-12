use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::SdnFw',
    VERSION_FROM      => 'lib/Apache/SdnFw.pm', # finds $VERSION
    PREREQ_PM         => {
		'DBI' => 0,
		'DBD::Pg' => 0,
		'Template' => 0,
		'Time::CTime' => 0,
		'LWP::UserAgent' => 0,
		'Crypt::CBC' => 0,
		'Crypt::Blowfish' => 0,
		'XML::Dumper' => 0,
		'XML::Simple' => 0,
		'Net::SMTP::SSL' => 0,
		'Net::FTP' => 0,
		'Digest::MD5' => 0,
		'MIME::Base64' => 0,
		'MIME::QuotedPrint' => 0,
		'Date::Format' => 0,
		'Data::Dumper' => 0,
		'Lingua::EN::Numbers' => 0,
		'Google::SAML::Response' => 0,
		}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache/SdnFw.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Sutton <chris@smalldognet.com>') : ()),
);
