requires   "Data::Dumper";
requires   "XSLoader";

recommends "Data::Dumper"             => "2.189";
recommends "Perl::Tidy";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
    };

on "test" => sub {
    requires   "Test::More"               => "0.90";
    requires   "Test::Warnings";

    recommends "Test::More"               => "1.302207";
    };
