use 5.008005;
use ExtUtils::MakeMaker;


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache2-Protocol-ESMTP',
    AUTHOR	      => 'Mike Smith <mike@mailchannels.com>',
    VERSION_FROM      => 'lib/Apache2/Protocol/ESMTP.pm', # finds $VERSION
    PREREQ_PM         => {
			    'Apache2::Protocol' => '',
			    'Apache2::ServerUtil' => ''
			}, # e.g., Module::Name => 1.1
);


