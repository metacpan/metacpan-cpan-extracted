requires "Carp" => "0";
requires "Class::Load" => "0";
requires "Clone" => "0";
requires "Dancer" => "0";
requires "Dancer::Plugin" => "0";
requires "Dancer::Plugin::REST" => "0";
requires "Dancer::Response" => "0";
requires "File::ShareDir::Tarball" => "0";
requires "Hash::Merge" => "0";
requires "JSON" => "0";
requires "List::AllUtils" => "0";
requires "Moo" => "0";
requires "MooX::Singleton" => "0";
requires "MooseX::MungeHas" => "0";
requires "Path::Tiny" => "0";
requires "PerlX::Maybe" => "0";
requires "overload" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Deep" => "0";
  requires "Test::More" => "0";
  requires "Test::WWW::Mechanize::PSGI" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::ShareDir::Install" => "0.06";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::PAUSE::Permissions" => "0";
  requires "Test::Vars" => "0";
};
