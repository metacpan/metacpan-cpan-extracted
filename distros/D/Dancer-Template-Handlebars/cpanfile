requires "Dancer::Config" => "0";
requires "Dancer::Template::Abstract" => "0";
requires "Module::Runtime" => "0";
requires "Moo" => "0";
requires "Sub::Attribute" => "0";
requires "Text::Handlebars" => "0";
requires "Try::Tiny" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Dancer" => "0";
  requires "Dancer::Test" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "lib" => "0";
  requires "parent" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::PAUSE::Permissions" => "0";
  requires "Test::Vars" => "0";
};
