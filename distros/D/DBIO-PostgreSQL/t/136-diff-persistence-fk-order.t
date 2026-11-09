use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff;

# karr k121 (7): SET LOGGED / SET UNLOGGED in the order of the foreign keys.
#
# WHAT this holds: the server refuses SET UNLOGGED at a table that references
# a logged table, and SET LOGGED at one that references an unlogged one. So
# going to UNLOGGED the referencing table is changed first, going to LOGGED
# the referenced one -- whatever the names say. Where two tables of the
# change reference each other, no order works and the diff is refused instead
# of writing statements the server will not take. The order comes from the
# model's foreign_keys section, with no database (t/136-...-live.t asks a
# server).

sub table {
  my ($name, $persistence) = @_;
  return ("public.$name" => {
    schema_name => 'public', table_name => $name, kind => 'r', persistence => $persistence,
  });
}

sub fk {
  my ($from, @to) = @_;
  return ("public.$from" => [ map { +{
    constraint_name => "${from}_${_}_fk", remote_schema => 'public', remote_table => $_,
    local_columns => ["${_}_id"], remote_columns => ['id'],
  } } @to ]);
}

# $from and $to give the persistence of each name; the keys are the
# references, from => [to...].
sub model {
  my ($persistence, @names) = @_;
  return {
    tables  => { map { table($_, $persistence) } @names },
    columns => { map { ("public.$_" => []) } @names },
  };
}

sub statements {
  my ($source, $target, %fks) = @_;
  $source->{foreign_keys} = { map { fk($_, @{ $fks{$_} }) } keys %fks };
  $target->{foreign_keys} = { %{ $source->{foreign_keys} } };
  return [ map { $_->as_sql } @{ DBIO::PostgreSQL::Diff->new(source => $source, target => $target)->operations } ];
}

# The names are chosen so that the order of the names is the wrong one.
# to UNLOGGED: the referencing table first.
is_deeply statements(model(p => qw( a_parent z_child )), model(u => qw( a_parent z_child )),
    z_child => ['a_parent']),
  [ 'ALTER TABLE public.z_child SET UNLOGGED;', 'ALTER TABLE public.a_parent SET UNLOGGED;' ],
  'to UNLOGGED the referencing table comes first, ahead of the one that sorts earlier';

# to LOGGED: the referenced table first.
is_deeply statements(model(u => qw( a_child z_parent )), model(p => qw( a_child z_parent )),
    a_child => ['z_parent']),
  [ 'ALTER TABLE public.z_parent SET LOGGED;', 'ALTER TABLE public.a_child SET LOGGED;' ],
  'to LOGGED the referenced table comes first, ahead of the one that sorts earlier';

# A chain, and a table that references nothing among them: the rest stays in
# the order of the names.
is_deeply statements(model(p => qw( a b c d )), model(u => qw( a b c d )),
    a => ['b'], b => ['c']),
  [ map { "ALTER TABLE public.$_ SET UNLOGGED;" } qw( a b c d ) ],
  'a chain a -> b -> c is changed from a; d, which has no key, keeps the order of the names';
is_deeply statements(model(p => qw( a b c d )), model(u => qw( a b c d )),
    c => ['b'], b => ['a'], d => ['a']),
  [ map { "ALTER TABLE public.$_ SET UNLOGGED;" } qw( c b d a ) ],
  'a chain c -> b -> a is changed from c; a stays last (b, d have to be ahead of a)';

# No foreign key: the order of the names, as before.
is_deeply statements(model(p => qw( b a )), model(u => qw( b a ))),
  [ map { "ALTER TABLE public.$_ SET UNLOGGED;" } qw( a b ) ],
  'without a foreign key the order is that of the names';

# A table that references itself is no constraint on the order.
is_deeply statements(model(p => qw( a )), model(u => qw( a )), a => ['a']),
  [ 'ALTER TABLE public.a SET UNLOGGED;' ],
  'a table that references itself is changed';

# A key to a table that does not change asks for no order.
{
  my $source = model(p => qw( a b ));
  my $target = model(p => qw( a b ));
  $target->{tables}{'public.b'}{persistence} = 'u';
  is_deeply statements($source, $target, b => ['a']),
    [ 'ALTER TABLE public.b SET UNLOGGED;' ],
    'a key to a table that is not changed is not in the way';
}

# A cycle: refused, naming the tables and the way out; nothing is built.
for my $to ([ p => 'u', 'UNLOGGED' ], [ u => 'p', 'LOGGED' ]) {
  my ($from, $into, $word) = @$to;
  my $ops = eval {
    my $s = model($from, qw( a b ));
    my $t = model($into, qw( a b ));
    $s->{foreign_keys} = { fk(a => 'b'), fk(b => 'a') };
    $t->{foreign_keys} = $s->{foreign_keys};
    DBIO::PostgreSQL::Diff->new(source => $s, target => $t)->operations;
  };
  my $error = $@;
  is $ops, undef, "a cycle of keys going to $word builds no operation";
  like $error, qr/\Arefusing to diff: public\.a, public\.b reference each other and are to be $word\b/m,
    '... and the diff is refused naming the tables';
  like $error, qr/No statement was generated\./, '... and says that nothing was generated';
}

done_testing;
