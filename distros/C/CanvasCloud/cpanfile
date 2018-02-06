requires "Hash::Merge" => "0";
requires "IO::String" => "0";
requires "JSON" => "0";
requires "LWP::UserAgent" => "0";
requires "Module::Load" => "0";
requires "Moose" => "0";
requires "URI" => "0";
requires "namespace::autoclean" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "FindBin" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::EOL" => "0";
  requires "Test::More" => "0.88";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "strict" => "0";
  requires "warnings" => "0";
};
