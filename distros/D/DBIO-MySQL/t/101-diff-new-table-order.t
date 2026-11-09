use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k106 (upgrade out of an empty database): the order in
# which a diff creates new tables.
#
# WHY IT MATTERS. diff_toplevel (core) hands the new tables over in name order.
# A child whose name sorts before its parent was created first, and the server
# refused it ("Failed to open the referenced table"); two tables that reference
# each other could not be created in any order with the foreign keys inline.
# install_ddl could do both, the upgrade could not. What this file claims, for
# two hand made models of an upgrade out of nothing:
#   1. a referenced new table is created before the one that references it;
#   2. tables free of each other stay in name order, and a self reference is
#      no dependency;
#   3. a foreign key that closes a cycle is not in the CREATE TABLE but an
#      ADD FOREIGN KEY after every CREATE TABLE and every index;
#   4. a foreign key to a table that already exists stays inline.

use DBIO::MySQL::Diff;

my $int = sub { { column_name => $_[0], column_type => 'int(11)', not_null => 1, is_pk => ($_[1] ? 1 : 0) } };
my $fk = sub {
  my ($name, $from, $to) = @_;
  return { constraint_name => $name, from_columns => [$from], to_table => $to,
    to_columns => ['id'], on_update => 'NO ACTION', on_delete => 'CASCADE' };
};
# table => [ [columns], [fks] ]
sub model {
  my (%t) = @_;
  return {
    tables       => { map { $_ => { table_name => $_, engine => 'InnoDB' } } keys %t },
    columns      => { map { my $n = $_; $n => [ map { $int->($_, $_ eq 'id') } @{ $t{$n}[0] } ] } keys %t },
    indexes      => { map { $_ => {} } keys %t },
    foreign_keys => { map { $_ => $t{$_}[1] } grep { $t{$_}[1] && @{ $t{$_}[1] } } keys %t },
  };
}
sub statements {
  my ($source, $target) = @_;
  return [ map { $_->as_sql =~ s/\s+/ /gr } @{ DBIO::MySQL::Diff->new(source => $source, target => $target)->operations } ];
}
sub order { [ map { /^CREATE TABLE `(\w+)`/ ? $1 : () } @{ $_[0] } ] }

my $empty = model();

{
  my $s = statements($empty, model(
    child  => [ ['id', 'parent_id'], [ $fk->('child_fk', 'parent_id', 'parent') ] ],
    parent => [ ['id'] ],
  ));
  is_deeply order($s), [qw/parent child/], 'a child named before its parent comes after it';
  like $s->[1], qr/FOREIGN KEY \(`parent_id`\) REFERENCES `parent`\(`id`\) ON DELETE CASCADE/, '... foreign key inline, with its action';
}

{
  my $s = statements($empty, model(
    a => [ ['id', 'c_id'], [ $fk->('a_fk', 'c_id', 'c') ] ],
    b => [ ['id'] ],
    c => [ ['id', 'b_id'], [ $fk->('c_fk', 'b_id', 'b') ] ],
    d => [ ['id', 'd_id'], [ $fk->('d_fk', 'd_id', 'd') ] ],
  ));
  is_deeply order($s), [qw/b c a d/], 'chain a -> c -> b: b, c, a; free table d in name order after a; a self reference is no dependency';
  like $s->[-1], qr/^CREATE TABLE `d`.*FOREIGN KEY \(`d_id`\) REFERENCES `d`/, '... the self reference stays inline';
}

{
  my $s = statements($empty, model(
    a => [ ['id', 'b_id'], [ $fk->('a_fk', 'b_id', 'b') ] ],
    b => [ ['id', 'a_id'], [ $fk->('b_fk', 'a_id', 'a') ] ],
  ));
  is_deeply order($s), [qw/a b/], 'a cycle: tables in name order';
  unlike $s->[0], qr/FOREIGN KEY/, '... the first table is written without the foreign key that closes the cycle';
  like $s->[1], qr/^CREATE TABLE `b`.*FOREIGN KEY \(`a_id`\) REFERENCES `a`/, '... the second has its own';
  like $s->[2], qr/^ALTER TABLE `a` ADD CONSTRAINT `a_fk` FOREIGN KEY \(`b_id`\) REFERENCES `b`\(`id`\) ON DELETE CASCADE;$/,
    '... the closing one is an ADD FOREIGN KEY, last, with its action';
  is scalar(@$s), 3, '... and nothing else';
}

# karr k106: the cycle is broken wherever, the constraints are the same ones with
# the same names. zz and aa reference each other, aa references cc too (the
# source names of install_ddl are A=zz, B=aa, C=cc, another order than the table
# names): the diff breaks at aa, install_ddl at zz, and both end in the same three
# named foreign keys, so the diff after the upgrade is empty.
{
  my $s = statements($empty, model(
    zz => [ ['id', 'aa_id'], [ $fk->('zz_aa_id_fk', 'aa_id', 'aa') ] ],
    aa => [ ['id', 'zz_id', 'cc_id'], [ $fk->('aa_zz_id_fk', 'zz_id', 'zz'), $fk->('aa_cc_id_fk', 'cc_id', 'cc') ] ],
    cc => [ ['id'] ],
  ));
  is_deeply order($s), [qw/cc aa zz/], 'moniker order is not table order: cc, then the cycle by table name';
  my @named = sort map { /CONSTRAINT `(\w+)` FOREIGN KEY/g } @$s;
  is_deeply \@named, [qw/aa_cc_id_fk aa_zz_id_fk zz_aa_id_fk/], '... every foreign key is written once, with its fixed name';
  like $s->[-1], qr/^ALTER TABLE `\w+` ADD CONSTRAINT `\w+_fk` FOREIGN KEY/, '... the one that closes the cycle is an ADD CONSTRAINT with a name';
}

{
  my $source = model(parent => [ ['id'] ]);
  my $s = statements($source, model(
    parent => [ ['id'] ],
    child  => [ ['id', 'parent_id'], [ $fk->('child_fk', 'parent_id', 'parent') ] ],
  ));
  like $s->[0], qr/^CREATE TABLE `child`.*FOREIGN KEY \(`parent_id`\) REFERENCES `parent`/, 'a foreign key to an existing table stays inline';
  is scalar(@$s), 1, '... one statement';
}

done_testing;
