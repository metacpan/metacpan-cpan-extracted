use strict;
use warnings;
use Test::More;

# Offline (karr k27): Informix holds one index over a column list (-350). Two
# declarations over the same columns -- two indexes, an index and a unique
# constraint, two unique constraints, an index and a unique column -- are
# refused by install_ddl naming BOTH, never one of them dropped silently.
# What says nothing more stays legitimate: a unique constraint over exactly the
# primary key, and a plain index over a foreign key's columns.

use DBIO::Core;
use DBIO::Schema;
use DBIO::Informix::DDL;

my $n = 0;
sub ddl_with {
  my (%o) = @_;
  $n++;
  my $sc = "T::K27a::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my @classes;
  my $make = sub {
    my ($name, $table, $cols, $pk, $extra) = @_;
    my $rc = "${sc}::Result::$name";
    { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); $INC{"T/K27a/S${n}/Result/$name.pm"} = 1; }
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk);
    push @classes, [ $name => $rc, $extra ];
  };
  $make->(Parent => 'parent', [ id => { data_type => 'integer' } ], ['id']);
  $make->(Child => 'child',
    [ (map { $_ => { data_type => 'integer' } } qw(id pid b)),
      (map { $_ => { data_type => 'integer', is_unique => 1 } } @{ $o{unique_cols} // [] }),
      (map { $_ => { data_type => 'integer' } } grep { my $c = $_; !grep { $_ eq $c } @{ $o{unique_cols} // [] } } 'a') ],
    ['id'], sub {
      my $rc = shift;
      $rc->belongs_to(parent => "${sc}::Result::Parent", 'pid');
      $rc->add_unique_constraint($_->[0] => $_->[1]) for @{ $o{constraints} // [] };
      $rc->result_source_instance->add_index_declaration($_) for @{ $o{indexes} // [] };
    });
  $_->[2]->($_->[1]) for grep { $_->[2] } @classes;
  $sc->register_class($_->[0] => $_->[1]) for @classes;
  return eval { DBIO::Informix::DDL->install_ddl($sc) } // "ERR: $@";
}

sub refused {
  my ($label, $out, @names) = @_;
  like $out, qr/^ERR: /, "$label: refused";
  for my $name (@names) { like $out, qr/\Q$name\E/, "... names '$name'" }
  like $out, qr/-350/, '... and says why (-350)';
}

refused 'two indexes over the same columns',
  ddl_with(indexes => [ { name => 'ix_one', columns => [qw(a b)] }, { name => 'ix_two', columns => [qw(a b)] } ]),
  qw(ix_one ix_two);

refused 'an index and a unique constraint',
  ddl_with(constraints => [ [ uq_ab => [qw(a b)] ] ], indexes => [ { name => 'ix_ab', columns => [qw(a b)] } ]),
  qw(ix_ab uq_ab);

refused 'a unique index and a unique constraint',
  ddl_with(constraints => [ [ uq_ab => [qw(a b)] ] ], indexes => [ { name => 'ix_ab', columns => [qw(a b)], type => 'unique' } ]),
  qw(ix_ab uq_ab);

refused 'two unique constraints',
  ddl_with(constraints => [ [ uq_one => [qw(a b)] ], [ uq_two => [qw(a b)] ] ]),
  qw(uq_one uq_two);

refused 'a unique column and an index',
  ddl_with(unique_cols => ['a'], indexes => [ { name => 'ix_a', columns => ['a'] } ]),
  qw(ix_a a);

refused 'an index over the primary key',
  ddl_with(indexes => [ { name => 'ix_pk', columns => ['id'] } ]),
  qw(ix_pk), 'primary key';

refused 'two plain indexes over a foreign key',
  ddl_with(indexes => [ { name => 'ix_p1', columns => ['pid'] }, { name => 'ix_p2', columns => ['pid'] } ]),
  qw(ix_p1 ix_p2);

# legitimate: says nothing more
{
  my $out = ddl_with(constraints => [ [ uq_id => ['id'] ] ]);
  unlike $out, qr/^ERR/, 'a unique constraint over exactly the primary key is fine';
  unlike $out, qr/uq_id/, '... and is not written';
}
{
  my $out = ddl_with(indexes => [ { name => 'ix_pid', columns => ['pid'] } ]);
  unlike $out, qr/^ERR/, 'a plain index over a foreign key is fine (the key builds one)';
  unlike $out, qr/ix_pid/, '... and is not written';
}
{
  my $out = ddl_with(constraints => [ [ uq_ab => [qw(a b)] ] ],
    indexes => [ { name => 'ix_ba', columns => [qw(b a)] }, { name => 'ix_a', columns => ['a'] } ]);
  unlike $out, qr/^ERR/, 'another order, a prefix: different column lists, built';
  like $out, qr/CREATE INDEX ix_ba/, '... ix_ba';
}

done_testing;
