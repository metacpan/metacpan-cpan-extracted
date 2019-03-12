requires "Beam::Service" => "0";
requires "Beam::Wire" => "1.019";
requires "List::Util" => "1.33";
requires "Module::Runtime" => "0";
requires "Moo" => "2";
requires "Path::Tiny" => "0.072";
requires "Pod::Find" => "0";
requires "Pod::Simple::SimpleTree" => "0";
requires "Term::ANSIColor" => "0";
requires "Types::Path::Tiny" => "0";
requires "Types::Standard" => "0";
requires "perl" => "5.010";

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Mock::MonkeyPatch" => "0";
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
