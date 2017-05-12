use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::3DSecure::Cardinal',
    VERSION_FROM      => 'lib/Business/3DSecure/Cardinal.pm', # finds $VERSION
    PREREQ_PM         => {
                           'Business::3DSecure' => 0,
                           'Error'              => 0,
                           'LWP::UserAgent'     => 0,
                           'SOAP::Lite'         => 0, 
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/3DSecure/Cardinal.pm', # retrieve abstract from module
       AUTHOR         => 'Clayton Cottingham <clayton@wintermarket.net>') : ()),
);
