requires "Class::Load" => "0";
requires "Dancer::Plugin" => "0";
requires "Moo" => "0";
requires "Moo::Role" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";
recommends "Class::Load::XS" => "0";

on 'test' => sub {
  requires "Dancer" => "0";
  requires "Dancer::Test" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "List::Util" => "0";
  requires "Test::More" => "0.96";
  requires "perl" => "5.010";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
