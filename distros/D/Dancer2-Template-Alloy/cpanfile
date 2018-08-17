requires "Carp" => "0";
requires "Dancer2::Core::Role::Template" => "0";
requires "Moo" => "0";
requires "Template::Alloy" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Test::More" => "0";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  requires "Module::Build::Tiny" => "0.034";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  suggests "JSON::PP" => "2.27300";
};
