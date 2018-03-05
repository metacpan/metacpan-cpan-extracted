requires "CHI" => "0";
requires "Carp" => "0";
requires "Dancer" => "1.32";
requires "Dancer::Factory::Hook" => "0";
requires "Dancer::Plugin" => "0";
requires "Dancer::Response" => "0";
requires "Dancer::SharedData" => "0";
requires "Moo" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Dancer::Test" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "lib" => "0";
  requires "perl" => "v5.10.0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::Vars" => "0";
};
