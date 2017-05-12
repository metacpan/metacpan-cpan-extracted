use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DJabberd::SASL::NTLM',
    VERSION_FROM      => 'lib/DJabberd/SASL/NTLM.pm', # finds $VERSION
    PREREQ_PM         => {
        'DJabberd' => 0.84
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DJabberd/SASL/NTLM.pm', # retrieve abstract from module
       AUTHOR         => 'Vladimir Lettiev <thecrux@gmail.com>') : ()),
);
