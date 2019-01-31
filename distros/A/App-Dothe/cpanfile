requires "File::Wildcard" => "0";
requires "Graph::Directed" => "0";
requires "List::AllUtils" => "0";
requires "Log::Any" => "0";
requires "Log::Any::Adapter" => "0";
requires "Moose" => "0";
requires "MooseX::App::Simple" => "0";
requires "Path::Tiny" => "0";
requires "PerlX::Maybe" => "0";
requires "Ref::Util" => "0";
requires "Text::Template" => "0";
requires "Type::Tiny" => "0";
requires "Types::Standard" => "0";
requires "YAML::XS" => "0";
requires "experimental" => "0";
requires "perl" => "v5.20.0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "strict" => "0";
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
