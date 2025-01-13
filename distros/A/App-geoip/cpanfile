requires   "Archive::Zip";
requires   "DBI";
requires   "Data::Dumper";
requires   "Getopt::Long";
requires   "JSON::PP";
requires   "LWP::Simple";
requires   "List::Util";
requires   "Math::Trig";
requires   "Net::CIDR";
requires   "Pod::Text";
requires   "Socket";
requires   "Text::CSV_XS"             => "1.39";

recommends "Archive::Zip"             => "1.68";
recommends "DBI"                      => "1.646";
recommends "Data::Dumper"             => "2.189";
recommends "Getopt::Long"             => "2.58";
recommends "JSON::PP"                 => "4.16";
recommends "LWP::Simple"              => "6.77";
recommends "Math::Trig"               => "1.62";
recommends "Net::CIDR"                => "0.21";
recommends "Pod::Usage"               => "2.03";
recommends "Socket"                   => "2.038";
recommends "Text::CSV_XS"             => "1.59";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
    };

on "build" => sub {
    requires   "Config";
    };

on "test" => sub {
    requires   "Test::More";
    };
