requires "Alien::SwaggerUI" => "0";
requires "Beam::Minion" => "0.007";
requires "CPAN::Testers::Schema" => "0.022";
requires "Cpanel::JSON::XS" => "0";
requires "File::Share" => "0";
requires "Import::Base" => "0.012";
requires "JSON::MaybeXS" => "0";
requires "JSON::Validator" => "1.07";
requires "Log::Any" => "1.045";
requires "Log::Any::Adapter::MojoLog" => "0.02";
requires "Mercury" => "0.015";
requires "Minion::Backend::mysql" => "0.12";
requires "Mojolicious" => "7.40";
requires "Mojolicious::Plugin::Config" => "0";
requires "Mojolicious::Plugin::OpenAPI" => "1.21";
requires "perl" => "5.024";
recommends "DateTime" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Mock::MonkeyPatch" => "0";
  requires "SQL::Translator" => "0.11018";
  requires "Test::Lib" => "0";
  requires "Test::More" => "1.001005";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
  recommends "CPAN::Testers::Fact::LegacyReport" => "0";
  recommends "CPAN::Testers::Fact::TestSummary" => "0";
  recommends "CPAN::Testers::Report" => "0";
  recommends "DBD::SQLite" => "0";
  recommends "Test::Reporter" => "0";
  recommends "Test::Reporter::Transport::Null" => "0";
  recommends "Test::mysqld" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::ShareDir::Install" => "0.06";
};
