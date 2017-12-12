requires "Beam::Runner" => "0.014";
requires "Beam::Wire" => "1.019";
requires "Getopt::Long" => "2.36";
requires "Minion" => "8";
requires "Module::Runtime" => "0";
requires "Mojolicious" => "7";
requires "perl" => "5.010";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Minion::Backend::SQLite" => "3.001";
  requires "Mock::MonkeyPatch" => "0";
  requires "Mojo::SQLite" => "2.002";
  requires "Test::Fatal" => "0";
  requires "Test::Lib" => "0";
  requires "Test::More" => "1.001005";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
