requires 'parent', 0;
requires 'indirect', 0;
requires 'curry', '>= 1.001';
requires 'Future', '>= 0.46';
requires 'Log::Any', '>= 1.050';
requires 'Ryu::Async', '>= 0.017';
requires 'Database::Async', '>= 0.013';
requires 'URI::postgres', 0;
requires 'URI::QueryParam', 0;
requires 'Future::AsyncAwait', '>= 0.28';
requires 'Template', '>= 2.28';
requires 'File::HomeDir';
requires 'Path::Tiny';
requires 'Config::Tiny';

requires 'Protocol::Database::PostgreSQL', '>= 1.005';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';
    requires 'Test::MockModule';
    requires 'File::Temp';
};

on 'develop' => sub {
	requires 'Test::CPANfile', '>= 0.02';
};
