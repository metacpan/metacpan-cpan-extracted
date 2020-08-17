requires 'DBI', '1.639';
requires 'OpenTracing::GlobalTracer';
requires 'OpenTracing::Implementation';
requires 'Package::Constants';
requires 'Scope::Context';
requires 'SQL::Statement', '1.412';
requires 'Syntax::Feature::Maybe';
requires 'syntax';

on test => sub {
    requires 'Test::Most';
    requires 'Test::OpenTracing::Integration', 'v0.102.1';
    recommends 'DBD::SQLite';
    recommends 'DBD::mysql';
    recommends 'Test::mysqld';
    recommends 'DBD::Pg';
    recommends 'Test::PostgreSQL';
};
