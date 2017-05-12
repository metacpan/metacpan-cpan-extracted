use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::StoredTransaction',
    VERSION_FROM      => 'lib/Business/OnlinePayment/StoredTransaction.pm', # finds $VERSION
    PREREQ_PM         => { Business::OnlinePayment => '2.01',
                           Crypt::OpenSSL::RSA => '0.21',
                           Crypt::CBC => '2.12',
                           Crypt::Blowfish => '2.09',
                           Storable => '2.12',
                           MIME::Base64 => '3.01',
                           Test::More => '0.47',
                           Digest::MD5 => '2.33'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/OnlinePayment/StoredTransaction.pm', # retrieve abstract from module
       AUTHOR         => 'mock <mock@obscurity.com>') : ()),
);
