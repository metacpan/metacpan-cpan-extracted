use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::WebMoney',
    VERSION_FROM      => 'lib/Business/WebMoney.pm', # finds $VERSION
    PREREQ_PM         => {
	    'LWP::UserAgent' => 0,
	    'Crypt::SSLeay' => 0,
	    'Net::SSL' => 0,
	    'XML::LibXML' => 0,
	    'HTTP::Request' => 0,
	    'File::Spec' => 0,
	    'POSIX' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/WebMoney.pm', # retrieve abstract from module
       AUTHOR         => 'Alexander Lourier <aml@rulezz.ru>') : ()),
);
