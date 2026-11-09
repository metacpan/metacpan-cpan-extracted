use strict;
use warnings;
use Test::More;

# Offline (karr k28, k29): the target of a foreign key is a primary key or
# unique constraint over the same columns IN THE SAME ORDER as the key
# references them. A key (b, a) against REFERENCES t(a, b) is -297 on the
# server (measured on Informix 15.0.1, the same for a primary key), although
# the column sets are equal. install_ddl therefore writes the column pairs in
# the order of the target key (as dbio-oracle does): a belongs_to onto a key
# in another order is built, as FOREIGN KEY (y, x) REFERENCES parent(b, a),
# never refused and never written in an order the server rejects.

use DBIO::Core;
use DBIO::Schema;
use DBIO::Informix::DDL;

my $n = 0;
sub ddl_with {
  my (%o) = @_;
  $n++;
  my $sc = "T::K29::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my @classes;
  my $make = sub {
    my ($name, $table, $cols, $pk, $extra) = @_;
    my $rc = "${sc}::Result::$name";
    { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); $INC{"T/K29/S${n}/Result/$name.pm"} = 1; }
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk);
    $extra->($rc) if $extra;
    push @classes, [ $name => $rc ];
  };
  $make->(Parent => 'parent',
    [ a => { data_type => 'integer' }, b => { data_type => 'integer' } ],
    $o{pk} // ['a'], sub {
      my $rc = shift;
      $rc->add_unique_constraint(parent_ab => $o{uc}) if $o{uc};
    });
  $make->(Child => 'child',
    [ id => { data_type => 'integer' }, x => { data_type => 'integer' }, y => { data_type => 'integer' } ],
    ['id'], sub {
      $_[0]->belongs_to(parent => "${sc}::Result::Parent", { 'foreign.a' => 'self.x', 'foreign.b' => 'self.y' });
    });
  $sc->register_class(@$_) for @classes;
  return eval { DBIO::Informix::DDL->install_ddl($sc) } // "ERR: $@";
}

for my $case (
  [ 'a primary key (b, a)',        pk => [qw/b a/] ],
  [ 'a unique constraint (b, a)',  uc => [qw/b a/] ],
) {
  my ($label, @opt) = @$case;
  my $out = ddl_with(@opt);
  unlike $out, qr/^ERR/, "a foreign key onto $label: built, not refused" or diag $out;
  like $out, qr/FOREIGN KEY \(y, x\) REFERENCES parent\(b, a\)/,
    '... with the pairs in the order of the target key';
  unlike $out, qr/REFERENCES parent\(a, b\)/, '... never in the order of the foreign column names';
}
{
  my $out = ddl_with(pk => [qw/a b/]);
  unlike $out, qr/^ERR/, 'a primary key (a, b) in the key order: written';
  like $out, qr/FOREIGN KEY \(x, y\) REFERENCES parent\(a, b\)/, '... as a key';
}
{
  my $out = ddl_with(pk => ['a'], uc => [qw/a b/]);
  unlike $out, qr/^ERR/, 'a unique constraint (a, b) in the key order: written';
}
{
  my $out = ddl_with(pk => [qw/b a/], uc => [qw/a b/]);
  unlike $out, qr/^ERR/, 'one target in the right order is enough, whatever the others say';
}

done_testing;
