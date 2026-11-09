use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL;
use My::Test qw(deploy_schema);

# WHY: updateX/deleteX name one row by its key. A key argument that is
# silently ignored lets a call with contradicting keys touch a row the caller
# did not mean (karr k10), and a source without a primary key has no row
# identity to update or delete by at all (karr k11).

{
  package KR::Result::Acct;
  use DBIO;
  __PACKAGE__->table('accts');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    email => { data_type => 'varchar', is_nullable => 0 },
    code  => { data_type => 'varchar', is_nullable => 0 },
    name  => { data_type => 'varchar', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(by_code  => ['code']);
  __PACKAGE__->add_unique_constraint(by_email => ['email']);
}
{
  package KR::Result::Pair;
  use DBIO;
  __PACKAGE__->table('pairs');
  __PACKAGE__->add_columns(
    a    => { data_type => 'integer', is_nullable => 0 },
    b    => { data_type => 'integer', is_nullable => 0 },
    note => { data_type => 'varchar', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('a', 'b');
  __PACKAGE__->add_unique_constraint(by_note => ['note']);
}
{
  package KR::Result::NoPk;
  use DBIO;
  __PACKAGE__->table('nopks');
  __PACKAGE__->add_columns(
    label => { data_type => 'varchar', is_nullable => 0 },
    val   => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->add_unique_constraint(by_label => ['label']);
}
{
  package KR::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class( Acct => 'KR::Result::Acct' );
  __PACKAGE__->register_class( Pair => 'KR::Result::Pair' );
  __PACKAGE__->register_class( NoPk => 'KR::Result::NoPk' );
}

my $db = KR::Schema->connect('dbi:SQLite:dbname=:memory:');
deploy_schema($db);
my $r      = DBIO::GraphQL->to_graphql($db, mutations => 1);
my $schema = $r->{schema};
my $exec   = $r->{execute};

sub gql { $exec->($_[0], undef, $db, {}) }

sub seed {
  $db->resultset('Acct')->delete({ all => 1 });
  $db->resultset('Pair')->delete({ all => 1 });
  $db->resultset('Acct')->create({ id => 1, email => 'a@x', code => 'A', name => 'one' });
  $db->resultset('Acct')->create({ id => 2, email => 'b@x', code => 'B', name => 'two' });
  $db->resultset('Pair')->create({ a => 1, b => 10, note => 'x' });
}

# Complete primary key decides alone: an unknown pk is not found, and the
# unique columns beside it are data.
seed();
{
  my $res = gql('mutation { deleteAcct(id: 99, code: "B") }');
  ok(!$res->{errors}, 'deleteAcct unknown id: no error');
  ok(!$res->{data}{deleteAcct}, 'unknown id deletes nothing');
  is($db->resultset('Acct')->count, 2, 'both rows remain');
}

# Two complete unique constraints must not be guessed between (k10 case 2).
seed();
{
  my $res = gql('mutation { deleteAcct(email: "nobody@x", code: "B") }');
  ok($res->{errors}, 'deleteAcct with two complete constraints is rejected');
  is($db->resultset('Acct')->count, 2, 'no row deleted');

  $res = gql('mutation { updateAcct(email: "nobody@x", code: "B", name: "changed") { id email } }');
  ok($res->{errors}, 'updateAcct with two complete constraints is rejected');
  my $row2 = $db->resultset("Acct")->find(2);
  is($row2 ? $row2->email : undef, 'b@x', 'row 2 keeps its email');
}

# One complete constraint alone still works.
seed();
{
  my $res = gql('mutation { updateAcct(code: "B", name: "renamed") { id name } }');
  ok(!$res->{errors}, 'updateAcct by one unique constraint: no error');
  is($res->{data}{updateAcct}{name}, 'renamed', 'row found by code');
  $res = gql('mutation { deleteAcct(email: "a@x") }');
  is($res->{data}{deleteAcct}, 1, 'deleteAcct by email works');
}

# A complete pk wins over constraint columns beside it.
seed();
{
  my $res = gql('mutation { deleteAcct(email: "a@x", id: 2) }');
  ok(!$res->{errors}, 'complete pk + email: no error');
  is($res->{data}{deleteAcct}, 1, 'the pk row is deleted');
  ok($db->resultset('Acct')->find(1), 'the email row is untouched');
  ok(!$db->resultset('Acct')->find(2), 'row 2 is gone');
}

# Partial primary key beside a constraint is rejected, not ignored (k10 case 1).
seed();
{
  my $res = gql('mutation { deletePair(a: 999, note: "x") }');
  ok($res->{errors}, 'deletePair partial pk + unique is rejected');
  like($res->{errors}[0]{message}, qr/primary key/i, 'message names the primary key');
  is($db->resultset('Pair')->count, 1, 'the foreign row survives');

  $res = gql('mutation { updatePair(a: 999, note: "x") { a b note } }');
  ok($res->{errors}, 'updatePair partial pk + unique is rejected');
}

# Partial primary key alone names no row.
seed();
{
  my $res = gql('mutation { deletePair(a: 1) }');
  ok(!$res->{errors}, 'deletePair with a partial pk alone: no error');
  ok(!$res->{data}{deletePair}, 'and deletes nothing');
  is($db->resultset('Pair')->count, 1, 'the row survives');
}

# k11: a source without a primary key gets neither updateX, deleteX nor the
# singular query; createX and the plural query stay.
{
  my $q = $schema->query->fields;
  my $m = $schema->mutation->fields;
  ok(!exists $m->{updateNoPk}, 'no updateNoPk');
  ok(!exists $m->{deleteNoPk}, 'no deleteNoPk');
  ok(!exists $q->{noPk},       'no singular noPk query');
  ok(exists $m->{createNoPk},  'createNoPk stays');
  ok(exists $q->{allNoPks},    'allNoPks stays');
  ok(exists $m->{updateAcct} && exists $m->{deleteAcct} && exists $q->{acct},
    'sources with a primary key keep all three');

  my $res = gql('mutation { createNoPk(label: "l", val: 1) { label val } }');
  ok(!$res->{errors}, 'createNoPk works') or diag explain $res->{errors};
}

done_testing;
