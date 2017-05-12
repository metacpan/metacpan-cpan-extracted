requires "AnyEvent" => "0";
requires "Moo" => "2.0";
requires "PerlX::Maybe" => "0.003";
requires "Protocol::WebSocket" => "0.20";
requires "URI" => "1.53";
requires "URI::ws" => "0";
requires "perl" => "5.008";
recommends "EV" => "0";
recommends "IO::Socket::SSL" => "0";
recommends "Math::Random::Secure" => "0";
recommends "Net::SSLeay" => "0";
recommends "PerlX::Maybe::XS" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Protocol::WebSocket" => "0.20";
  requires "Test::More" => "0.94";
  requires "perl" => "5.008";
};

on 'test' => sub {
  recommends "Devel::Cycle" => "0";
  recommends "EV" => "0";
  recommends "Mojolicious" => "3.0";
  recommends "Test::Memory::Cycle" => "0";
  recommends "Test::Warn" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "File::Spec" => "0";
  requires "Test::CPAN::Changes" => "0";
  requires "Test::EOL" => "0";
  requires "Test::Fixme" => "0.07";
  requires "Test::More" => "0.94";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "0";
  requires "Test::Pod::Coverage" => "0";
  requires "Test::Pod::Spelling::CommonMistakes" => "0";
  requires "Test::Spelling" => "0";
  requires "Test::Strict" => "0";
  requires "YAML" => "0";
};
