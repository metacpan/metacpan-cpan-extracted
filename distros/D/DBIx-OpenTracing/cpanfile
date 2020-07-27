requires 'DBI';
requires 'OpenTracing::GlobalTracer';
requires 'OpenTracing::Implementation';
requires 'Syntax::Feature::Maybe';
requires 'Scope::Context';
requires 'syntax';

on test => sub {
    requires 'Test::Most';
    recommends 'DBD::mysql';
    recommends 'DBD::SQLite';
    recommends 'Test::mysqld';
    requires 'Test::OpenTracing::Integration', 'v0.102.1';
};
