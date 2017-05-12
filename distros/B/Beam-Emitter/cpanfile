requires "Carp" => "0";
requires "Module::Runtime" => "0";
requires "Moo" => "0";
requires "Scalar::Util" => "0";
requires "Types::Standard" => "0.008";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::API" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::Lib" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
  recommends "Test::LeakTrace" => "0";
  recommends "curry" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
