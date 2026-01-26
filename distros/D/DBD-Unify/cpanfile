requires   "Carp";
requires   "DBI"                      => "1.42";
requires   "DynaLoader";

recommends "DBI"                      => "1.647";


on "configure" => sub {
    requires   "Config";
    requires   "Cwd";
    requires   "DBI::DBD";
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.76";
    };

on "build" => sub {
    requires   "Config";
    requires   "File::Copy";
    requires   "File::Find";
    };

on "test" => sub {
    requires   "Test::Harness";
    requires   "Test::More"               => "0.90";

    recommends "Test::More"               => "1.302219";
    };
