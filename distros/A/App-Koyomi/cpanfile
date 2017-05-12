requires 'Class::Accessor::Lite', '0.08';
requires 'DateTime', '1.18';
requires 'DateTime::Format::MySQL', '0.05';
requires 'DateTime::TimeZone', '1.88';
requires 'DBD::SQLite', '1.46';
requires 'IO::Prompt::Tiny', '0.003';
requires 'Log::Minimal', '0.19';
requires 'Module::Load', '0.32';
requires 'Perl6::Slurp', '0.051005';
requires 'Proc::Wait3', '0.04';
requires 'Smart::Args', '0.12';
requires 'TOML', '0.96';
requires 'Text::ASCIITable', '0.20';
requires 'Text::Diff', '1.41';
requires 'Teng', '0.28';
requires 'YAML::XS', '0.54';

on test => sub {
    requires 'Test::Base', '0.88';
    requires 'Test::More', '1.001009';
};

on build => sub {
    requires 'TAP::Harness', '3.34';
};

on configure => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::CPANfile', '0.9010';
};
