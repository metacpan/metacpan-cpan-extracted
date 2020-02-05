requires   "Data::Dumper";
requires   "DynaLoader";

recommends "Data::Dumper"             => "2.173";
recommends "Perl::Tidy";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";
    };

on "test" => sub {
    requires   "Test::More"               => "0.90";
    requires   "Test::Warnings";

    recommends "Test::More"               => "1.302171";
    };
