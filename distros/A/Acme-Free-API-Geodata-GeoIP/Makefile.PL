use 5.038002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::Free::API::Geodata::GeoIP',
    VERSION_FROM      => 'lib/Acme/Free/API/Geodata/GeoIP.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        "WWW::Mechanize" => 2.0,
        "JSON::XS" => 4.0,
        "Data::Dumper" => 0,
    },
        "EXE_FILES" => [
        "bin/geoip"
    ],

    ABSTRACT_FROM     => 'lib/Acme/Free/API/Geodata/GeoIP.pm', # retrieve abstract from module
    AUTHOR            => 'Rene Schickbauer <cavac@cpan.org>',
    LICENSE           => 'perl',
);
