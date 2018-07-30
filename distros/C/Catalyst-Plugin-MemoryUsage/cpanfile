requires "Devel::CheckOS" => "0";
requires "List::Util" => "0";
requires "MRO::Compat" => "0";
requires "Memory::Usage" => "0";
requires "Moose::Role" => "0";
requires "Number::Bytes::Human" => "0";
requires "Text::SimpleTable" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "v5.10.0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Catalyst" => "0";
  requires "Catalyst::Controller" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "Test::WWW::Mechanize::Catalyst" => "0";
  requires "lib" => "0";
  requires "parent" => "0";
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
