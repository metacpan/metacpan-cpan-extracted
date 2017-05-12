requires "Dancer2" => "0.10";
requires "Dancer2::Core::Role::SessionFactory" => "0";
requires "Dancer2::Core::Types" => "0";
requires "Moo" => "0";
requires "Session::Storage::Secure" => "0.010";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Dancer2" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0.22";
  requires "HTTP::Date" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "LWP::UserAgent" => "0";
  requires "List::Util" => "0";
  requires "Test::More" => "0.96";
  requires "Test::TCP" => "1.30";
  requires "YAML" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
