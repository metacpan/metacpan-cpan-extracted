requires "Beam::Minion" => "0.007";
requires "Beam::Runner" => "0.013";
requires "Beam::Wire" => "1.020";
requires "CPAN::Testers::Report" => "0";
requires "CPAN::Testers::Schema" => "0.018";
requires "DBI" => "0";
requires "Data::FlexSerializer" => "0";
requires "Getopt::Long" => "2.36";
requires "Import::Base" => "0.012";
requires "JSON::MaybeXS" => "0";
requires "Log::Any" => "1.046";
requires "Metabase::User::Profile" => "0";
requires "Minion" => "8";
requires "Minion::Backend::SQLite" => "0";
requires "Minion::Backend::mysql" => "0.11";
requires "Sereal" => "0";
requires "perl" => "5.024";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "1.001005";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
  recommends "Test::mysqld" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
