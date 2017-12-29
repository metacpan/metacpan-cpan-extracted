requires "Code::TidyAll::Plugin" => "0";
requires "Moo" => "0";
requires "Net::Works::Address" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "Code::TidyAll" => "0";
  requires "File::Slurper" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "Test::More" => "0";
  requires "open" => "0";
  requires "utf8" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
};
