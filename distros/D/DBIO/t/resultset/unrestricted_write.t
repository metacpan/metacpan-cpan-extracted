use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

# A condition is true, false or SQL at every node, and SELECT, UPDATE and
# DELETE read it alike. A resultset whose condition is true is unrestricted:
# update and delete refuse it unless the call says { all => 1 }.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;
my $sm      = $storage->sql_maker;

my $where = sub {
  my ($cond) = @_;
  my ($sql) = $sm->where($cond);
  $sql =~ s{[()\s]+}{ }g; $sql =~ s{\A | \z}{}g;
  return $sql;
};

my $TRUE  = '';
my $FALSE = 'WHERE 0=1';

# --- the truth table, one row per rule of the decision
my @table = (
  [ '{}'                      => {},                                   $TRUE  ],
  [ 'undef'                   => undef,                                $TRUE  ],
  [ '-and => []'              => { -and => [] },                       $TRUE  ],
  [ '-and => {}'              => { -and => {} },                       $TRUE  ],
  [ '-not_in => []'           => { id => { -not_in => [] } },          $TRUE  ],
  [ 'and of true nodes'       => { -and => [ {}, { -and => [] } ] },   $TRUE  ],
  [ '[] as a whole'           => [],                                   $FALSE ],
  [ '-or => []'               => { -or => [] },                       $FALSE ],
  [ '-in => []'               => { id => { -in => [] } },              $FALSE ],
  [ 'or of false nodes'       => { -or => [ { id => { -in => [] } }, { -or => [] } ] }, $FALSE ],
  [ 'and: false member'       => { -and => [ { id => { -in => [] } }, { name => 'a' } ] }, $FALSE ],
  [ 'and: key beside -or=>[]' => { name => 'a', -or => [] },          $FALSE ],
  [ 'and: true members drop'  => { name => 'a', -and => [] },          'WHERE "name" = ?' ],
  [ 'or: true member'         => { -or => [ {}, { name => 'a' } ] },   $TRUE  ],
  [ 'or: -not_in => [] member'=> { -or => [ { id => { -not_in => [] } }, { name => 'a' } ] }, $TRUE ],
  [ 'or: true inside a list'  => [ {}, { name => 'a' } ],              $TRUE  ],
  [ 'or: false members drop'  => { -or => [ [], { name => 'a' } ] },   'WHERE "name" = ?' ],
  [ 'or in and, true result'  => { name => 'a', -or => [ { -or => [] }, { -and => [] } ] }, 'WHERE "name" = ?' ],
);

for my $row (@table) {
  my ($label, $cond, $expect) = @$row;
  is $where->($cond), $expect, "where: $label";

  # the same node in UPDATE and DELETE
  my ($dsql) = $sm->delete('artist', $cond);
  my ($usql) = $sm->update('artist', { rank => 1 }, $cond);
  my ($ssql) = $sm->select('artist', ['id'], $cond);
  my $tail = $expect eq $TRUE ? qr/\A[^W]*\z/ : qr/\Q$expect\E\z/;
  for ([ delete => $dsql ], [ update => $usql ], [ select => $ssql ]) {
    my ($stmt, $sql) = @$_;
    $sql =~ s{[()\s]+}{ }g;
    $sql =~ s{ \z}{};
    like $sql, $tail, "$stmt: $label";
  }
}

# --- ResultSet: update and delete refuse a true condition
my $artists = $schema->resultset('Artist');

my @true_rs = (
  [ 'no condition'  => $artists ],
  [ '{}'            => $artists->search_rs({}) ],
  [ 'undef'         => $artists->search_rs(undef) ],
  [ '-and => []'    => $artists->search_rs({ -and => [] }) ],
  [ '-not_in => []' => $artists->search_rs({ artistid => { -not_in => [] } }) ],
  [ '-or with a true member' => $artists->search_rs({ -or => [ {}, { name => 'a' } ] }) ],
);

for my $row (@true_rs) {
  my ($label, $rs) = @$row;
  throws_ok { $rs->delete }
    qr/delete on an unrestricted resultset: pass \{ all => 1 \}/,
    "delete refuses: $label";
  throws_ok { $rs->update({ rank => 1 }) }
    qr/update on an unrestricted resultset: pass \{ all => 1 \}/,
    "update refuses: $label";
  throws_ok { $rs->delete_all }
    qr/delete_all on an unrestricted resultset/,
    "delete_all refuses: $label";
  throws_ok { $rs->update_all({ rank => 1 }) }
    qr/update_all on an unrestricted resultset/,
    "update_all refuses: $label";
}

# the empty list of an id set (the form that deletes a table)
my @ids = ();
{
  $storage->reset_captured;
  my $rs = $artists->search_rs({ -or => [ map { { artistid => $_ } } @ids ] });
  lives_ok { $rs->delete } 'an empty -or list is false, not unrestricted';
  my ($q) = grep { $_->{op} eq 'delete' } $storage->captured_queries;
  like $q->{sql}, qr/WHERE 0=1/, 'and it deletes nothing: 0=1';
}

# --- { all => 1 } renders as before
{
  $storage->reset_captured;
  $artists->delete({ all => 1 });
  $artists->update({ rank => 1 }, { all => 1 });
  my @q = $storage->captured_queries;
  is $q[0]{sql}, 'DELETE FROM "artist"', 'delete({ all => 1 }) is the plain DELETE';
  is $q[1]{sql}, 'UPDATE "artist" SET "rank" = ?', 'update(..., { all => 1 }) is the plain UPDATE';
}

# --- rows restricts (subselect), a condition restricts
{
  $storage->reset_captured;
  lives_ok { $artists->search_rs(undef, { rows => 1 })->delete }
    'delete on a resultset with rows lives';
  lives_ok { $artists->search_rs({ name => 'a' })->delete } 'delete with a condition lives';
  lives_ok { $artists->search_rs({ name => 'a' })->update({ rank => 2 }) }
    'update with a condition lives';
}

# --- the options hash takes exactly one key
throws_ok { $artists->delete({ all => 1, force => 1 }) }
  qr/does not know the option\(s\): force/, 'delete: an unknown key throws';
throws_ok { $artists->search_rs({ name => 'a' })->update({ rank => 1 }, { every => 1 }) }
  qr/does not know the option\(s\): every/, 'update: an unknown key throws, also when restricted';
throws_ok { $artists->delete('all') } qr/options must be a hash/, 'delete: not a hash throws';

# --- Result->delete as a class call: a condition restricts, none throws
{
  my $class = ref $artists->new_result({});
  $class->result_source_instance($schema->source('Artist'));   # a class call needs a bound source
  $storage->reset_captured;
  throws_ok { $class->delete } qr/delete on an unrestricted resultset: pass \{ all => 1 \}/,
    'class delete without a condition throws';
  ok ! (grep { $_->{op} eq 'delete' } $storage->captured_queries), 'and deletes nothing';
  lives_ok { $class->delete({ name => 'a' }) } 'class delete with a condition lives';
}

done_testing;
