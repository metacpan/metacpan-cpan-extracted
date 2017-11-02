requires "Carp" => "0";
requires "Moo" => "0";
requires "perl" => "v5.14.0";
requires "utf8" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
  requires "strict" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Dist::Zilla" => "5";
  requires "Dist::Zilla::Plugin::AutoPrereqs" => "0";
  requires "Dist::Zilla::Plugin::ModuleBuild" => "0";
  requires "Dist::Zilla::Plugin::VersionFromMainModule" => "0";
  requires "Dist::Zilla::PluginBundle::Author::AMON" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Software::License::Perl_5" => "0";
  requires "Test::Kwalitee::Extra" => "0";
  requires "Test::More" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "strict" => "0";
};
