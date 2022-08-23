use 5.030000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CryptoTron::AddrTools',
    VERSION_FROM      => 'lib/CryptoTron/AddrTools.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Try::Catch' => '1.1.0', 'Bitcoin::Crypto::Base58' => '1.007'}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/CryptoTron/AddrTools.pm', # retrieve abstract from module
    AUTHOR            => 'Dr. Peter Netz <ztenretep@cpan.org>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
