requires "Authen::SASL::SASLprep" => "0";
requires "Carp" => "0";
requires "Crypt::URandom" => "0";
requires "Encode" => "0";
requires "MIME::Base64" => "0";
requires "Moo" => "1.001000";
requires "Moo::Role" => "1.001000";
requires "PBKDF2::Tiny" => "0.003";
requires "Try::Tiny" => "0";
requires "Types::Standard" => "0";
requires "namespace::clean" => "0";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "warnings" => "0";
recommends "String::Compare::ConstantTime" => "0.310";

on 'test' => sub {
  requires "Exporter" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::FailWarnings" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0.96";
  requires "base" => "0";
  requires "lib" => "0";
  requires "perl" => "5.008001";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Dist::Zilla" => "5";
  requires "Dist::Zilla::Plugin::Prereqs" => "0";
  requires "Dist::Zilla::Plugin::RemovePrereqs" => "0";
  requires "Dist::Zilla::Plugin::SurgicalPodWeaver" => "0.0021";
  requires "Dist::Zilla::PluginBundle::DAGOLDEN" => "0.061";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
};
