use strict;
use warnings;
use Test::More;

# Offline (karr k27): Informix wants a primary key or a unique CONSTRAINT as
# the target of a foreign key; a unique index alone is answered with -297
# (measured on Informix 15.0.1). install_ddl refuses such a key and says how
# to declare it, instead of writing a statement the server rejects.

use DBIO::Core;
use DBIO::Schema;
use DBIO::Informix::DDL;

my $n = 0;
sub ddl_with {
  my (%o) = @_;
  $n++;
  my $sc = "T::K27b::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my @classes;
  my $make = sub {
    my ($name, $table, $cols, $pk, $extra) = @_;
    my $rc = "${sc}::Result::$name";
    { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); $INC{"T/K27b/S${n}/Result/$name.pm"} = 1; }
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk);
    $extra->($rc) if $extra;
    push @classes, [ $name => $rc ];
  };
  $make->(Parent => 'parent',
    [ id => { data_type => 'integer' }, code => { data_type => 'integer', %{ $o{code_info} // {} } } ],
    ['id'], sub {
      my $rc = shift;
      $rc->add_unique_constraint(parent_code => ['code']) if $o{constraint};
      $rc->result_source_instance->add_index_declaration($_) for @{ $o{indexes} // [] };
    });
  $make->(Child => 'child', [ id => { data_type => 'integer' }, pcode => { data_type => 'integer' } ], ['id'], sub {
    $_[0]->belongs_to(parent => "${sc}::Result::Parent", { 'foreign.code' => 'self.pcode' });
  });
  $sc->register_class(@$_) for @classes;
  return eval { DBIO::Informix::DDL->install_ddl($sc) } // "ERR: $@";
}

for my $case (
  [ 'a declared unique index', indexes => [ { name => 'parent_code_ix', columns => ['code'], type => 'unique' } ] ],
  [ 'a unique column (is_unique)', code_info => { is_unique => 1 } ],
) {
  my ($label, @opt) = @$case;
  my $out = ddl_with(@opt);
  like $out, qr/^ERR: /, "a foreign key onto $label only: refused";
  like $out, qr/-297/, '... says what the server answers (-297)';
  like $out, qr/add_unique_constraint/, '... and how to declare it';
  like $out, qr/child.*parent|parent.*code/s, '... naming the tables and the column';
}

{
  my $out = ddl_with(constraint => 1);
  unlike $out, qr/^ERR/, 'a foreign key onto a unique constraint is written';
  like $out, qr/FOREIGN KEY \(pcode\) REFERENCES parent\(code\)/, '... as a key';
}

done_testing;
