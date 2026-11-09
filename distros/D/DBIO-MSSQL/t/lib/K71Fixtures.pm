package K71Fixtures;
# The cascade fixtures of t/94 (offline: the driver refuses or accepts) and
# t/95 (live: the server agrees). Each refused entry: label, tables, and the
# table and relationship the message names (alternatives where a cycle has no
# first key), one list for both so that they cannot drift.
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(schema_for rel without_artist_constraint @REFUSED @ALLOWED);

BEGIN { $ENV{CAG_ILLEGAL_ACCESSOR_NAME_OK} = 1 }

my $n = 0;
# A schema of the given tables. A table: [ name, { rels }, { cols } ]; a rel:
# [ relname, target table, from col, { attrs } ].
sub schema_for {
  my (@tables) = @_;
  my $class = "K94::S" . ++$n;
  eval "package $class; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); 1" or die $@;
  my @rels;
  for my $t (@tables) {
    my ($name, $rels, $cols, $extra) = @$t;
    my $rc = "$class\::Result::" . ucfirst $name;
    eval "package $rc; use base 'DBIO::Core'; 1" or die $@;
    $rc->table($name);
    my %cols = (id => { data_type => 'integer' }, %{ $cols || {} });
    for my $r (@{ $rels || [] }) {
      $cols{ $r->[2] } //= { data_type => 'integer', is_nullable => 1 };
    }
    $rc->add_columns(map { ($_ => $cols{$_}) } sort keys %cols);
    $rc->set_primary_key('id');
    $extra->($rc) if $extra;
    push @rels, [ $rc, $name, $rels || [] ];
  }
  for my $r (@rels) {
    my ($rc, $name, $rels) = @$r;
    $rc->belongs_to($_->[0] => "$class\::Result::" . ucfirst $_->[1], $_->[2], $_->[3] || {})
      for @$rels;
  }
  $class->register_class(ucfirst $_->[1] => $_->[0]) for @rels;
  return $class;
}


# The shared test schema of core declares add_unique_constraint(artist =>
# ['artistid']) on the table artist (Artist.pm). SQL Server keeps constraint
# and table names in one namespace (Msg 2714), so install_ddl refuses it
# (t/100). Tests that need the rest of that schema installed take the one
# constraint off the instance's source.
sub without_artist_constraint {
  my ($schema) = @_;
  my $source = $schema->source('Artist');
  my %u = $source->unique_constraints;
  delete $u{artist};
  $source->_unique_constraints(\%u);
  return $schema;
}

sub rel { my ($name, $to, $col, %a) = @_; [ $name, $to, $col, { %a } ] }

our @REFUSED = (
  [ 'self-reference with ON DELETE CASCADE',
    [ ['node', [ rel(up => 'node', 'up_id', on_delete => 'cascade') ]] ], 'node', 'up' ],
  [ 'self-reference with ON DELETE SET NULL',
    [ ['node', [ rel(up => 'node', 'up_id', on_delete => 'set null') ]] ], 'node', 'up' ],
  [ 'self-reference with ON UPDATE CASCADE',
    [ ['node', [ rel(up => 'node', 'up_id', on_update => 'cascade') ]] ], 'node', 'up' ],
  [ 'two keys to one parent, both CASCADE',
    [ ['p'], ['c', [ rel(a => 'p', 'a_id', on_delete => 'cascade'), rel(b => 'p', 'b_id', on_delete => 'cascade') ]] ],
    'c', 'b' ],
  [ 'two keys to one parent, CASCADE and SET NULL',
    [ ['p'], ['c', [ rel(a => 'p', 'a_id', on_delete => 'cascade'), rel(b => 'p', 'b_id', on_delete => 'set null') ]] ],
    'c', 'b' ],
  [ 'two keys to one parent, ON UPDATE CASCADE twice',
    [ ['p'], ['c', [ rel(a => 'p', 'a_id', on_update => 'cascade'), rel(b => 'p', 'b_id', on_update => 'cascade') ]] ],
    'c', 'b' ],
  [ 'a cycle of two tables with CASCADE',
    [ ['a', [ rel(to_b => 'b', 'b_id', on_delete => 'cascade') ]],
      ['b', [ rel(to_a => 'a', 'a_id', on_delete => 'cascade') ]] ], 'a|b', 'to_a|to_b' ],
  [ 'a cycle of three tables with CASCADE',
    [ ['a', [ rel(to_b => 'b', 'b_id', on_delete => 'cascade') ]],
      ['b', [ rel(to_c => 'c', 'c_id', on_delete => 'cascade') ]],
      ['c', [ rel(to_a => 'a', 'a_id', on_delete => 'cascade') ]] ], 'a|b|c', 'to_a|to_b|to_c' ],
  [ 'a diamond of CASCADE keys',
    [ ['r'], ['x', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['y', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['z', [ rel(x => 'x', 'x_id', on_delete => 'cascade'), rel(y => 'y', 'y_id', on_delete => 'cascade') ]] ],
    'z', 'y' ],
  [ 'a cycle of two tables: CASCADE one way, SET NULL back',
    [ ['a', [ rel(to_b => 'b', 'b_id', on_delete => 'cascade') ]],
      ['b', [ rel(to_a => 'a', 'a_id', on_delete => 'set null') ]] ], 'a|b', 'to_a|to_b' ],
  [ 'a CASCADE chain and a SET NULL key to the same table',
    [ ['r'], ['x', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['z', [ rel(x => 'x', 'x_id', on_delete => 'set null'), rel(r => 'r', 'r_id', on_delete => 'set null') ]] ],
    'z', 'r' ],
);

our @ALLOWED = (
  [ 'a parent with a CASCADE child',
    [ ['p'], ['c', [ rel(p => 'p', 'p_id', on_delete => 'cascade', on_update => 'cascade') ]] ] ],
  [ 'a self-reference with NO ACTION (and RESTRICT)',
    [ ['node', [ rel(up => 'node', 'up_id'), rel(up2 => 'node', 'up2_id', on_delete => 'restrict') ]] ] ],
  [ 'two keys to one parent, CASCADE and NO ACTION',
    [ ['p'], ['c', [ rel(a => 'p', 'a_id', on_delete => 'cascade'), rel(b => 'p', 'b_id') ]] ] ],
  [ 'ON DELETE CASCADE on one key, ON UPDATE CASCADE on the other',
    [ ['p'], ['c', [ rel(a => 'p', 'a_id', on_delete => 'cascade'), rel(b => 'p', 'b_id', on_update => 'cascade') ]] ] ],
  [ 'a cycle of two tables, one key NO ACTION',
    [ ['a', [ rel(to_b => 'b', 'b_id', on_delete => 'cascade') ]],
      ['b', [ rel(to_a => 'a', 'a_id') ]] ] ],
  [ 'a cycle of SET NULL keys (the update reaches no referenced column)',
    [ ['a', [ rel(to_b => 'b', 'b_id', on_delete => 'set null') ]],
      ['b', [ rel(to_a => 'a', 'a_id', on_delete => 'set null') ]] ] ],
  [ 'a CASCADE chain',
    [ ['r'], ['x', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['y', [ rel(x => 'x', 'x_id', on_delete => 'cascade') ]] ] ],
  [ 'a diamond with one leg NO ACTION',
    [ ['r'], ['x', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['y', [ rel(r => 'r', 'r_id', on_delete => 'cascade') ]],
      ['z', [ rel(x => 'x', 'x_id', on_delete => 'cascade'), rel(y => 'y', 'y_id') ]] ] ],
  [ 'a diamond whose legs are SET NULL on columns nothing references',
    [ ['r'], ['x', [ rel(r => 'r', 'r_id', on_delete => 'set null') ]],
      ['y', [ rel(r => 'r', 'r_id', on_delete => 'set null') ]],
      ['z', [ rel(x => 'x', 'x_id', on_delete => 'cascade'), rel(y => 'y', 'y_id', on_delete => 'cascade') ]] ] ],
);

1;
