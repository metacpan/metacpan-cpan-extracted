use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Amazon::SendToKindle',
    VERSION_FROM      => 'lib/Amazon/SendToKindle.pm', # finds $VERSION
    PREREQ_PM         => {
		'Net::SMTP::TLS' => 0.12,
		'MIME::Lite' => 3.029
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Amazon/SendToKindle.pm', # retrieve abstract from module
       AUTHOR         => 'Nathan Campos <nathanpc@dreamintech.net>') : ()),
);
