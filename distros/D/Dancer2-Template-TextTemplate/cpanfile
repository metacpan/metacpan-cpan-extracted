requires "CHI" => "0";
requires "Carp" => "0";
requires "Dancer2::Core::Role::Template" => "0";
requires "Dancer2::Core::Types" => "0";
requires "Moo" => "0";
requires "MooX::Types::MooseLike::Base" => "0";
requires "Safe" => "2.26";
requires "Scalar::Util" => "0";
requires "Text::Template" => "1.46";
requires "namespace::clean" => "0";
requires "perl" => "5.010_000";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "File::Temp" => "0";
  requires "IPC::System::Simple" => "0";
  requires "Test::API" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0.88";
  requires "autodie" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.3601";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Kwalitee" => "1.12";
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "version" => "0.9901";
};
