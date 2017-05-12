use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::Yubico',
    VERSION_FROM      => 'lib/AnyEvent/Yubico.pm', # finds $VERSION
    PREREQ_PM         => {
        "AnyEvent::HTTP" => "2.13",
        "UUID::Tiny" => "1.0",
        "MIME::Base64" => "3.13",
        "Digest::HMAC_SHA1" => "1.02",
        "URI::Escape" => "1.54",
        "Net::SSLeay" => "1.36"
    }, # e.g., Module::Name => 1.1
    BUILD_REQUIRES     => {
        "Test::More" => "0.98",
        "Test::Exception" => "0.29",
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/Yubico.pm', # retrieve abstract from module
       AUTHOR         => 'Dain Nilsson <dain@yubico.com>') : ()),
);
