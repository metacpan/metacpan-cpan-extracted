use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::X509::CRL',
    VERSION_FROM      => 'lib/Crypt/X509/CRL.pm', # finds $VERSION
    PREREQ_PM         => {Convert::ASN1 => 0.19}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/X509/CRL.pm', # retrieve abstract from module
       AUTHOR         => 'Duncan Segrest') : ()),
);
