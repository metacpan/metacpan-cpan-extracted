requires 'parent', 0;
requires 'indirect', 0;
requires 'curry', '>= 1.001';
requires 'Future', '>= 0.38';
requires 'Log::Any', '>= 1.050';
requires 'Ryu::Async', '>= 0.014';
requires 'Database::Async', '>= 0.004';
requires 'URI::postgres', 0;
requires 'URI::QueryParam', 0;
requires 'Future::AsyncAwait', '>= 0.24';
requires 'Template', '>= 2.28';

requires 'Protocol::Database::PostgreSQL', '>= 1.001';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';
	suggests 'Test::PostgreSQL', '>= 1.26';
};

on 'develop' => sub {
	requires 'Test::CPANfile', '>= 0.02';
};
