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
recommends "DBI"                      => "1.643";
recommends "Data::Dumper"             => "2.184";
recommends "Getopt::Long"             => "2.54";
recommends "JSON::PP"                 => "4.16";
recommends "LWP::Simple"              => "6.67";
recommends "Math::Trig"               => "1.23";
recommends "Net::CIDR"                => "0.21";
recommends "Pod::Usage"               => "2.03";
recommends "Socket"                   => "2.036";
recommends "Text::CSV_XS"             => "1.49";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";
    };

on "build" => sub {
    requires   "Config";
    };

on "test" => sub {
    requires   "Test::More";
    };
