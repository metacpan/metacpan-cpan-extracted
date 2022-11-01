use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'CryptoTron::JsonHttp',
    VERSION_FROM     => 'lib/CryptoTron/JsonHttp.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM        => {'Try::Catch' => '1.1.0',
                         'File::Basename' => '2.85',
                         'URI' => '1.76',
                         'POSIX' => '1.88',
                         'JSON::PP' => '4.11',
                         'LWP::UserAgent' => '6.43'}, # e.g., 'Module::Name' => '1.1'
    AUTHOR           => 'Dr. Peter Netz <ztenretep@cpan.org>',
    ABSTRACT         => 'Perl extension for use of with the Tron blockchain', # Direct definition of ABSTRACT
    LICENSE          => 'perl'
    # VERSION          => '0.01', # Direct definition of VERSION
    # ABSTRACT_FROM     => 'lib/CryptoTron/JsonHttp.pm', # retrieve abstract from module
    # Value must be from legacy list of licenses here
    # http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
