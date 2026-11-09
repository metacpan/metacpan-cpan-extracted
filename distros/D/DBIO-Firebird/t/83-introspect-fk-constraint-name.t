use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Introspect::ForeignKeys;

# OFFLINE (karr k55, core ADR 0021).
#
# WHY: the introspected model names a foreign key's constraint under
# `constraint_name`, the one key every driver's model uses, not the Firebird
# private `fk_id`. This asserts the hash ForeignKeys->fetch builds, from a
# stand-in handle answering the two rdb$ queries; there is no alias beside it.

{
  package Fake::Sth;
  sub new { my ($c, @rows) = @_; bless { rows => [@rows] }, $c }
  sub execute { 1 }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
  sub fetchrow_array   { my $r = shift @{ $_[0]{rows} }; $r ? @$r : () }

  package Fake::Dbh;
  sub new { bless {}, shift }
  sub prepare {
    my ($self, $sql) = @_;
    return Fake::Sth->new({
      'rdb$constraint_name' => 'T_C_O_FK   ', 'rdb$relation_name' => 'T   ',
      to_table => 'O   ', from_column => 'C   ',
      'rdb$update_rule' => 'RESTRICT', 'rdb$delete_rule' => 'CASCADE',
      'rdb$match_option' => 'FULL',
    }) if $sql =~ /rdb\$ref_constraints/ && $sql =~ /from_column/;
    return Fake::Sth->new(['ID   ']);
  }
}

my $fks = DBIO::Firebird::Introspect::ForeignKeys->fetch(Fake::Dbh->new, { T => 1 });
my ($fk) = @{ $fks->{T} };

is $fk->{constraint_name}, 'T_C_O_FK', 'the key carries constraint_name';
ok !exists $fk->{fk_id}, 'no fk_id beside it';
is_deeply [ $fk->{from_columns}, $fk->{to_table}, $fk->{to_columns} ],
  [ ['C'], 'O', ['ID'] ], 'rest of the shape unchanged';

done_testing;
