use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CryptoTron',
    PREREQ_PM         => {'Try::Catch' => '1.1.0',
                          'Inline::Python' => '0.57',
                          'Bitcoin::Crypto::Base58' => '1.007',
                          'URI' => '1.76',
                          'LWP::UserAgent' => '6.43',
                          'JSON::PP' => '4.11'
                         }, # e.g., 'Module::Name' => '1.1.0'
    ABSTRACT          => 'Perl extension for use with the blockchain of the crypto coin Tron.', # Abstract of module
    AUTHOR            => 'Dr. Peter Netz <ztenretep@cpan.org>', # Author of module
    VERSION_FROM      => 'lib/CryptoTron.pm', # Finds $VERSION, requires EU::MM from perl >= 5.5
    LICENSE           => 'mit',
    # Value must be from legacy list of licenses here
    # http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    # VERSION           => '0.01', # VERSION of module
    # ABSTRACT_FROM     => 'lib/CryptoTron/CryptoTron.pm', # Retrieve abstract from module
);
