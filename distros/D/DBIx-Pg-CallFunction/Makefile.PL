use inc::Module::Install;

name            'DBIx-Pg-CallFunction';
all_from        'lib/DBIx/Pg/CallFunction.pm';

license         'MIT';
requires        'DBI'             => '1.605';
requires        'DBD::Pg'         => 0;
requires        'Carp'            => 0;
test_requires   'Test::More'      => 0;
test_requires   'Test::Exception' => '0.32';

recommends      'JSON'            => 0;
recommends      'Plack::Request'  => 0;
install_script  'scripts/pg_proc_jsonrpc.psgi';

WriteAll;
