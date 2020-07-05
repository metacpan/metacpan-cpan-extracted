use strict;
use Test::More;
use DBIx::TempDB;

my %test = (mysql => $ENV{TEST_MYSQL_DSN}, pg => $ENV{TEST_PG_DSN}, sqlite => eval 'require DBD::SQLite;"sqlite:"');
delete $test{$_} for grep { !$test{$_} } keys %test;

plan skip_all => 'No live testing is set up' unless %test;

for my $test_case (sort keys %test) {
  subtest $test_case => sub {
    my $tmpdb1 = DBIx::TempDB->new($test{$test_case});
    create_table($tmpdb1);
    ok has_table($tmpdb1), 'tmpdb1 has table';

    my $tmpdb2 = DBIx::TempDB->new($test{$test_case});
    create_table($tmpdb2);
    ok has_table($tmpdb2), 'tmpdb2 has table';
    $tmpdb2->drop_databases;
    ok !can_connect($tmpdb1), 'tmpdb1 dropped';
    ok has_table($tmpdb2),    'tmpdb2 still has table';

    # drop_databases() will not fail if the database is already dropped
    $tmpdb2->drop_databases({self => 'include'});
    $tmpdb2->drop_databases({self => 'only'});
    $tmpdb2->drop_databases;
    ok !can_connect($tmpdb2), 'tmpdb2 dropped self';
  };
}

done_testing;

sub can_connect {
  return eval { DBI->connect(shift->dsn) };
}

sub create_table {
  DBI->connect(shift->dsn)->do('create table dbix_tempdb_drop_t (name text)');
}

sub has_table {
  !!grep {/dbix_tempdb_drop_t/} DBI->connect(shift->dsn)->tables(undef, undef, undef, undef);
}
