requires   "DBD::File"                => "0.42";
requires   "DBI"                      => "1.628";
requires   "SQL::Statement"           => "1.405";
requires   "Text::CSV_XS"             => "1.01";

recommends "DBD::File"                => "0.45";
recommends "DBI"                      => "1.649";
recommends "SQL::Statement"           => "1.414";
recommends "Text::CSV_XS"             => "1.62";

on "configure" => sub {
    requires   "DBI"                      => "1.628";
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.78";
    };

on "build" => sub {
    requires   "Config";
    };

on "test" => sub {
    requires   "Cwd";
    requires   "Encode";
    requires   "Test::Harness";
    requires   "Test::More"               => "0.90";
    requires   "charnames";

    recommends "Encode"                   => "3.12";
    recommends "Test::More"               => "1.302222";

    suggests   "Encode"                   => "3.24";
    };
