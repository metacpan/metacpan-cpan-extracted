# Add your requirements here
requires 'perl', 'v5.10.0'; # for kwalitee

requires 'DBIx::Connector::Retry', 'v0.900.2';
requires 'Moo';

requires 'Scalar::Util';
requires 'Storable';
requires 'Types::Standard';
requires 'Types::Common::Numeric';

requires 'Algorithm::Backoff::RetryTimeouts';
requires 'DBIx::ParseError::MySQL';

on test => sub {
    requires 'Test2::V0';
    requires 'Test2::Tools::Explain';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
