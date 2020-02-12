requires "Date::Holidays::Super";
requires "Exporter";
requires "base";
requires "constant";
requires "perl" => "5.008";
requires "strict";
requires "utf8";
requires "warnings";

on 'test' => sub {
  requires "ExtUtils::MakeMaker";
  requires "File::Spec::Functions";
  requires "List::Util";
  requires "Test::Fatal";
  requires "Test::More";
  requires "Test::Most";
  requires "version";
};

on 'test' => sub {
  recommends "CPAN::Meta";
  recommends "CPAN::Meta::Requirements" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
  requires "File::ShareDir::Install" => "0.03";
};

on 'develop' => sub {
  requires "Cwd";
  requires "DateTime";
  requires "Dist::Milla";
  requires "File::Spec";
  requires "File::Spec::Functions";
  requires "File::Temp";
  requires "JSON";
  requires "List::Util";
  requires "LWP::Simple";
  requires "Pod::Coverage::TrustPod";
  requires "Test::CPAN::Meta";
  requires "Test::More";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Time::Local";
};

