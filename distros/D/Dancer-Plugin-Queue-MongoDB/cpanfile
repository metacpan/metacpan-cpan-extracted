requires "Dancer::Plugin::Queue::Role::Queue" => "0";
requires "MongoDBx::Queue" => "1.000";
requires "Moose" => "0";
requires "MooseX::AttributeShortcuts" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Dancer" => "0";
  requires "Dancer::Plugin::Queue" => "0";
  requires "Dancer::Test" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "List::Util" => "0";
  requires "MongoDB" => "0.45";
  requires "Test::More" => "0.96";
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
