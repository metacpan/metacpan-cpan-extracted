use strict;
use warnings;
use Test::More;

# LIVE: data_type boolean is a BOOLEAN column (karr k36). Firebird 3 is the
# driver's minimum, which has the native type; before k36 the DDL wrote
# SMALLINT, so a schema installed from a boolean column introspected as
# smallint. Four claims, each one only a server can answer:
#
#  * install writes BOOLEAN (introspected as boolean) and the diff afterwards
#    is empty;
#  * 1 and 0 go in and come out through the ORM, on insert, select, update and
#    search;
#  * the words 'true' and 'false' mean what SQL means by them. DBD::Firebird
#    1.39 binds text and takes its Perl truth, so 'false' reached the server
#    as TRUE; the storage translates the two words;
#  * any other string is refused, not stored as TRUE;
#  * a FALSE the DBD has read comes back as '' and must be writable again:
#    copy, search on the read value, update with it;
#  * populate in void context (the bulk path, which does not pass the bind
#    hook) translates and refuses the same way;
#  * the bulk path handles a literal bind (\['?', [on => 'false']]) the same way;
#  * default_value 'true' / 'false' (any case) works too, as 0 / 1 do: the server takes DEFAULT '0' at CREATE TABLE
#    and fails every insert that uses it, so the DDL writes FALSE / TRUE.
#
# Skipped unless a DSN is provided (as t/19):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the table "k36_flag".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live boolean test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Deploy;
use DBIO::Firebird::Introspect;

{
  package K36Live::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package K36Live::Schema::Result::Flag;
  use DBIO 'Core';
  __PACKAGE__->table('k36_flag');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    on => { data_type => 'boolean', is_nullable => 1 },
    d0 => { data_type => 'boolean', is_nullable => 1, default_value => 0 },
    d1 => { data_type => 'boolean', is_nullable => 1, default_value => 1 },
    d2 => { data_type => 'boolean', is_nullable => 1, default_value => 'true' },
    d3 => { data_type => 'boolean', is_nullable => 1, default_value => 'False' },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  K36Live::Schema->register_class(Flag => 'K36Live::Schema::Result::Flag');
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my $schema = K36Live::Schema->connect($dsn, $user, $pass, {
  quote_names => 1, on_connect_call => 'use_softcommit',
});
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach Firebird server: $@";

my ($ver) = $dbh->selectrow_array(
  q{SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM rdb$database});
plan skip_all => "BOOLEAN needs Firebird 3 (server is $ver)" if ($ver =~ /^(\d+)/)[0] < 3;

sub cleanup { eval { $dbh->do('DROP TABLE "k36_flag"') } }
cleanup();

my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);
ok eval { $deploy->install; 1 }, 'install accepts a boolean column' or diag $@;

my ($col) = grep { $_->{column_name} eq 'on' }
  @{ DBIO::Firebird::Introspect->new(dbh => $dbh)->model->{columns}{k36_flag} };
is $col && $col->{data_type}, 'boolean', 'the installed column introspects as boolean, not smallint';

my $diff = eval { $deploy->diff };
ok $diff && !$diff->has_changes, 'and the diff afterwards is empty'
  or diag $diff ? $diff->as_sql : "diff failed: $@";

my $rs = $schema->resultset('Flag');
ok eval { $rs->create({ id => 1, on => 1 }); $rs->create({ id => 2, on => 0 });
          $rs->create({ id => 3, on => undef }); 1 }, 'insert 1, 0 and NULL' or diag $@;

my %got = map { $_->id => $_->on } $rs->search({}, { order_by => 'id' })->all;
ok $got{1},          'select: 1 reads back true';
ok defined $got{2} && !$got{2}, 'select: 0 reads back false (defined)';
ok !defined $got{3}, 'select: NULL stays NULL';

my $ids = sub { join ',', map { $_->id } $rs->search(@_, { order_by => 'id' })->all };
is $ids->({ on => 1 }), '1', 'search on => 1';
is $ids->({ on => 0 }), '2', 'search on => 0';

ok eval { $rs->find(1)->update({ on => 0 }); 1 }, 'update 1 -> 0' or diag $@;
ok !$rs->find(1)->on, '... and it reads back false';

# the words of SQL
ok eval { $rs->create({ id => 4, on => 'true' }); $rs->create({ id => 5, on => 'FALSE' }); 1 },
  q{insert 'true' and 'FALSE'} or diag $@;
ok  $rs->find(4)->on, q{'true' is stored true};
ok !$rs->find(5)->on, q{'false' is stored false, not true as the DBD alone would have it};
is $ids->({ on => 'false' }), '1,2,5', q{search on => 'false' finds the false rows};
ok eval { $rs->find(4)->update({ on => 'false' }); 1 }, q{update to 'false'} or diag $@;
ok !$rs->find(4)->on, '... and it reads back false';

# anything else is refused, and nothing is written
my $before = $rs->count;
eval { $rs->create({ id => 6, on => 'x' }) };
like $@, qr/BOOLEAN column 'on'/, q{a string that is neither 1, 0, 'true' nor 'false' is refused, naming the column};
is $rs->count, $before, '... and no row was written';
eval { $rs->find(1)->update({ on => 'nope' }) };
like $@, qr/BOOLEAN column 'on'/, '... on update as well';

# a FALSE read from the server is writable again
my $f = $rs->find(5);
ok defined $f->on && !$f->on, 'a FALSE row is read';
ok eval { $f->copy({ id => 8 }); 1 }, 'copy of a row holding FALSE' or diag $@;
ok !$rs->find(8)->on, '... and the copy is FALSE';
is $ids->({ on => $f->on }), '1,2,4,5,8', 'search on => the value read for FALSE finds the false rows';
ok eval { $rs->find(2)->update({ on => $f->on }); 1 }, 'update with the value read for FALSE' or diag $@;
ok eval { $rs->create({ id => 9, on => ($f->id == 99) }); 1 },
  q{flag => (a == b) with a false comparison ('') is accepted} or diag $@;
ok !$rs->find(9)->on, '... and stored FALSE';

# the bulk path
ok eval { $rs->populate([ [qw/id on/], [ 10, 'false' ], [ 11, 'true' ], [ 12, '' ], [ 13, 1 ], [ 14, undef ] ]); 1 },
  'populate (void context) with the SQL words' or diag $@;
my %bulk = map { $_->id => $_->on } $rs->search({ id => { -in => [10 .. 14] } })->all;
ok defined $bulk{10} && !$bulk{10}, q{bulk: 'false' is FALSE, not TRUE};
ok  $bulk{11}, q{bulk: 'true' is TRUE};
ok defined $bulk{12} && !$bulk{12}, q{bulk: '' is FALSE};
ok  $bulk{13}, 'bulk: 1 is TRUE';
ok !defined $bulk{14}, 'bulk: undef stays NULL';
ok eval { $rs->populate([ [qw/id on/], [ 15, \['?', [ on => 'false' ]] ], [ 16, \['?', [ on => 'true' ]] ] ]); 1 },
  'populate (void context) with literal binds' or diag $@;
ok defined $rs->find(15)->on && !$rs->find(15)->on, q{bulk, literal bind: 'false' is FALSE, not TRUE};
ok $rs->find(16)->on, q{bulk, literal bind: 'true' is TRUE};
my $n = $rs->count;
eval { $rs->populate([ [qw/id on/], [ 22, \['?', [ on => 1 ]] ], [ 23, \['?', [ on => 'x' ]] ] ]) };
like $@, qr/BOOLEAN column 'on'/, 'bulk, literal bind: another string is refused, naming the column';
is $rs->count, $n, '... and no row of that populate was written';
eval { $rs->populate([ [qw/id on/], [ 20, 1 ], [ 21, 'x' ] ]) };
like $@, qr/BOOLEAN column 'on'/, 'bulk: another string is refused, naming the column';
is $rs->count, $n, '... and no row of that populate was written';

# default_value 0 / 1
ok eval { $rs->create({ id => 30 }); 1 }, 'insert that takes the defaults of d0 and d1' or diag $@;
{
  my $r = $rs->find(30);
  ok defined $r->d0 && !$r->d0, 'default_value 0 is FALSE';
  ok $r->d1, 'default_value 1 is TRUE';
  ok $r->d2, q{default_value 'true' is TRUE};
  ok defined $r->d3 && !$r->d3, q{default_value 'False' is FALSE};
}

cleanup();
$schema->storage->disconnect;
done_testing;
