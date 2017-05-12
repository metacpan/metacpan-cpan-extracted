use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::FedEx::RateRequest',
    VERSION_FROM      => 'lib/Business/FedEx/RateRequest.pm', # finds $VERSION
    PREREQ_PM         => {   LWP::UserAgent=>0,
                             XML::Simple=>0,
		             Time::Piece=>0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/FedEx/RateRequest.pm', # retrieve abstract from module
       AUTHOR         => 'troxel AT perlworks.com>') : ()),
);
