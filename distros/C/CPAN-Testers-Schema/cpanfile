requires "DBIx::Class" => "0";
requires "DBIx::Class::Candy" => "0";
requires "DBIx::Class::InflateColumn::Serializer" => "0.09";
requires "DateTime" => "0";
requires "DateTime::Format::ISO8601" => "0";
requires "DateTime::Format::MySQL" => "0";
requires "File::Share" => "0";
requires "Import::Base" => "0.012";
requires "JSON::MaybeXS" => "0";
requires "Log::Any" => "1.045";
requires "Path::Tiny" => "0.072";
requires "SQL::Translator" => "0.11018";
requires "perl" => "5.024";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "CPAN::Testers::Fact::LegacyReport" => "0";
  requires "CPAN::Testers::Fact::TestSummary" => "0";
  requires "CPAN::Testers::Report" => "0";
  requires "DateTime::Format::SQLite" => "0";
  requires "Exporter" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Lib" => "0";
  requires "Test::More" => "1.001005";
  requires "Test::Reporter" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::ShareDir::Install" => "0.06";
};
