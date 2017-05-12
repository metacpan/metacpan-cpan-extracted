requires "Carp" => "0";
requires "Dancer2" => "0.203000";
requires "Dancer2::Core::HTTP" => "0.203000";
requires "Dancer2::Plugin" => "0";
requires "List::Util" => "0";
requires "perl" => "v5.12.0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Dancer2" => "0.203000";
  requires "Dancer2::Core::Request" => "0";
  requires "Data::Dumper" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "HTTP::Request::Common" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "JSON" => "0";
  requires "Module::Runtime" => "0";
  requires "Plack::Test" => "0";
  requires "Test::More" => "0";
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
