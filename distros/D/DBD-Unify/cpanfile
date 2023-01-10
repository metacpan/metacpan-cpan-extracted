requires   "Carp";
requires   "DBI"                      => "1.42";
requires   "DynaLoader";

recommends "DBI"                      => "1.643";

on "configure" => sub {
    requires   "Config";
    requires   "Cwd";
    requires   "DBI::DBD";
    requires   "ExtUtils::MakeMaker";
    };

on "build" => sub {
    requires   "Config";
    requires   "File::Copy";
    requires   "File::Find";
    };

on "test" => sub {
    requires   "Test::Harness";
    requires   "Test::More"               => "0.90";

    recommends "Test::More"               => "1.302191";
    };
