requires "Cache::Memcached" => "0";
requires "Carp" => "0";
requires "Dancer2" => "0.15000";
requires "Dancer2::Core::Role::SessionFactory" => "0";
requires "Moo" => "0";
requires "Type::Tiny" => "0";
requires "Types::Standard" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Dancer2" => "0.15000";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0.22";
  requires "HTTP::Cookies" => "0";
  requires "HTTP::Date" => "0";
  requires "HTTP::Request::Common" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "JSON" => "0";
  requires "Plack::Test" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
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
  requires "Test::Vars" => "0";
};
