requires "Alien::Base" => "0";
requires "List::Util" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "v5.8.0";

on 'build' => sub {
  requires "Alien::Build" => "0.32";
  requires "Alien::Build::MM" => "0.32";
  requires "ExtUtils::MakeMaker" => "6.52";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "Module::Metadata" => "0";
  requires "Test2::V0" => "0";
  requires "Test::Alien" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Alien::Build" => "1.40";
  requires "Alien::Build::MM" => "0.32";
  requires "Alien::Build::Plugin::Build::CMake" => "0.99";
  requires "ExtUtils::MakeMaker" => "6.52";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CleanNamespaces" => "0.15";
  requires "Test::EOF" => "0";
  requires "Test::EOL" => "0";
  requires "Test::MinimumVersion" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Portability::Files" => "0";
  requires "Test::TrailingSpace" => "0.0203";
};
