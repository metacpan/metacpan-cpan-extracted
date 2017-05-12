use strict;
use warnings;
use Test::More;
use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper;

my ($dsn, $user, $pass) = @ENV{map { "MAPPER_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{MAPPER_TEST_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $user);

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => $dsn,
    username => $user,
    password => $pass,
    db_schema => 'public',
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
ok( scalar(grep { /^pg_/ } $mapper->engine->get_tables) == 0 );

done_testing;
