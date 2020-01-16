requires   "Archive::Zip";
requires   "DBI";
requires   "Data::Dumper";
requires   "Getopt::Long";
requires   "JSON::PP";
requires   "LWP::Simple";
requires   "Math::Trig";
requires   "Net::CIDR";
requires   "Pod::Usage";
requires   "Socket";
requires   "Text::CSV_XS"             => "1.39";

recommends "Archive::Zip"             => "1.66";
recommends "DBI"                      => "1.642";
recommends "Data::Dumper"             => "2.173";
recommends "Getopt::Long"             => "2.51";
recommends "JSON::PP"                 => "4.04";
recommends "LWP::Simple"              => "6.43";
recommends "Math::Trig"               => "1.23";
recommends "Net::CIDR"                => "0.20";
recommends "Pod::Usage"               => "1.69";
recommends "Socket"                   => "2.029";
recommends "Text::CSV_XS"             => "1.40";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";
    };

on "build" => sub {
    requires   "Config";
    };

on "test" => sub {
    requires   "Test::More";
    };
