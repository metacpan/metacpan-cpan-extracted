requires "Beam::Runner" => "0";
requires "Beam::Service" => "0";
requires "Beam::Wire" => "1.023";
requires "List::Util" => "1.39";
requires "Log::Any" => "1.708";
requires "Moo" => "2.004000";
requires "Text::CSV" => "0";
requires "perl" => "5.020";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
  recommends "DBD::SQLite" => "1.56";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
