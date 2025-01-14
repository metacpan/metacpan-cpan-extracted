requires   "DBD::File"                => "0.42";
requires   "DBI"                      => "1.628";
requires   "SQL::Statement"           => "1.405";
requires   "Text::CSV_XS"             => "1.01";

recommends "DBD::File"                => "0.44";
recommends "DBI"                      => "1.643";
recommends "SQL::Statement"           => "1.414";
recommends "Text::CSV_XS"             => "1.59";

suggests   "DBI"                      => "1.646";

on "configure" => sub {
    requires   "DBI"                      => "1.628";
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
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
    recommends "Test::More"               => "1.302207";

    suggests   "Encode"                   => "3.21";
    };
