use strict;
use warnings;
use Test::More;

# LIVE (karr k55): data_type 'bool' is a BOOLEAN column, so everything the
# driver guards a BOOLEAN with (karr k36) holds for the alias as well.
#
# WHY: Type.pm writes bool as BOOLEAN, but the guards asked for the literal
# 'boolean': a bool column with default_value 0 became DEFAULT '0' (the server
# takes it and then fails every insert that uses the default), and 'false' was
# bound untranslated, which DBD::Firebird stores as TRUE. Claims, through the
# ORM as t/26 does for 'boolean':
#
#  * install writes BOOLEAN, default_value 0 / 'true' are FALSE / TRUE and an
#    insert that takes them works;
#  * create, update and search with 'true' / 'false' mean what SQL means;
#  * another string is refused, naming the column;
#  * populate in void context (the bulk path) translates the same way, also
#    with a literal bind.
#
# WARNING: creates and drops the table "k55_bool".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live bool test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Deploy;

{
  package K55Bool::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package K55Bool::Schema::Result::Flag;
  use DBIO 'Core';
  __PACKAGE__->table('k55_bool');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    on => { data_type => 'bool', is_nullable => 1 },
    d0 => { data_type => 'bool', is_nullable => 1, default_value => 0 },
    d2 => { data_type => 'BOOL', is_nullable => 1, default_value => 'true' },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  K55Bool::Schema->register_class(Flag => 'K55Bool::Schema::Result::Flag');
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my $schema = K55Bool::Schema->connect($dsn, $user, $pass, {
  quote_names => 1, on_connect_call => 'use_softcommit',
});
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach Firebird server: $@";

sub cleanup { eval { $dbh->do('DROP TABLE "k55_bool"') } }
cleanup();

my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);
ok eval { $deploy->install; 1 }, 'install accepts a bool column' or diag $@;

my $rs = $schema->resultset('Flag');

# default_value 0 / 'true'
ok eval { $rs->create({ id => 1 }); 1 }, 'insert that takes the defaults' or diag $@;
{
  my $r = $rs->find(1);
  ok defined $r->d0 && !$r->d0, 'bool, default_value 0 is FALSE';
  ok $r->d2, q{BOOL, default_value 'true' is TRUE};
}

# the words of SQL on create / update / search
ok eval { $rs->create({ id => 2, on => 'true' }); $rs->create({ id => 3, on => 'FALSE' }); 1 },
  q{create with 'true' and 'FALSE'} or diag $@;
ok  $rs->find(2)->on, q{bool: 'true' is stored true};
ok !$rs->find(3)->on, q{bool: 'false' is stored false, not true as the DBD alone would have it};
ok eval { $rs->find(2)->update({ on => 'false' }); 1 }, q{update to 'false'} or diag $@;
ok !$rs->find(2)->on, '... and it reads back false';
is join(',', map { $_->id } $rs->search({ on => 'false' }, { order_by => 'id' })->all), '2,3',
  q{search on => 'false' finds the false rows};

my $before = $rs->count;
eval { $rs->create({ id => 4, on => 'x' }) };
like $@, qr/BOOLEAN column 'on'/, 'another string is refused, naming the column';
is $rs->count, $before, '... and no row was written';

# the bulk path
ok eval { $rs->populate([ [qw/id on/], [ 10, 'false' ], [ 11, 'true' ], [ 12, '' ] ]); 1 },
  'populate (void context) with the SQL words' or diag $@;
my %bulk = map { $_->id => $_->on } $rs->search({ id => { -in => [10 .. 12] } })->all;
ok defined $bulk{10} && !$bulk{10}, q{bulk: 'false' is FALSE, not TRUE};
ok  $bulk{11}, q{bulk: 'true' is TRUE};
ok defined $bulk{12} && !$bulk{12}, q{bulk: '' is FALSE};
ok eval { $rs->populate([ [qw/id on/], [ 15, \['?', [ on => 'false' ]] ], [ 16, \['?', [ on => 'true' ]] ] ]); 1 },
  'populate (void context) with literal binds' or diag $@;
ok defined $rs->find(15)->on && !$rs->find(15)->on, q{bulk, literal bind: 'false' is FALSE};
ok $rs->find(16)->on, q{bulk, literal bind: 'true' is TRUE};
my $n = $rs->count;
eval { $rs->populate([ [qw/id on/], [ 20, 1 ], [ 21, 'x' ] ]) };
like $@, qr/BOOLEAN column 'on'/, 'bulk: another string is refused, naming the column';
is $rs->count, $n, '... and no row of that populate was written';

cleanup();
$schema->storage->disconnect;
done_testing;
