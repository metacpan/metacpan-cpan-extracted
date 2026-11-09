use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::DDL;

# karr k73 (review finding): the columns of a foreign key follow the order of
# the key it references. Measured: SQL Server wants the referenced column list
# in exactly the order of a primary key / unique constraint / unique index
# (Msg 1776 otherwise), and takes the pairing with the referencing columns as
# written. The classes used to sort the columns by the referencing name, so a
# primary key (b, a) could not be referenced. Live: t/106.

sub schema_for {
  my ($tag, $pk, $uniques, $cond, $fk_attrs) = @_;
  my $s = "K73O::${tag}::Schema";
  eval "package $s; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); 1" or die $@;
  my $p = "$s\::Result::P";
  eval "package $p; use base 'DBIO::Core'; 1" or die $@;
  $p->table('p');
  $p->add_columns(a => { data_type => 'int' }, b => { data_type => 'int' });
  $p->set_primary_key(@$pk) if $pk;
  $p->add_unique_constraint($_ => $uniques->{$_}) for sort keys %{ $uniques || {} };
  my $c = "$s\::Result::C";
  eval "package $c; use base 'DBIO::Core'; 1" or die $@;
  $c->table('c');
  $c->add_columns(id => { data_type => 'int' }, x => { data_type => 'int' }, y => { data_type => 'int' });
  $c->set_primary_key('id');
  $c->belongs_to(p => $p, $cond, $fk_attrs || {});
  $s->register_class(P => $p);
  $s->register_class(C => $c);
  return $s;
}

my $swap     = { 'foreign.a' => 'self.y', 'foreign.b' => 'self.x' };
my $straight = { 'foreign.a' => 'self.x', 'foreign.b' => 'self.y' };

# PK (b, a): the key order, not the order of the names of the referencing columns
{
  my $ddl = DBIO::MSSQL::DDL->install_ddl(schema_for('pkba', ['b', 'a'], undef, $swap));
  like($ddl, qr/CONSTRAINT PK_p PRIMARY KEY \(b, a\)/, 'the key is (b, a)');
  like($ddl,
    qr/ADD CONSTRAINT FK_c_x_y FOREIGN KEY \(x, y\) REFERENCES p \(b, a\);/,
    'PK (b, a): the foreign key lists the referenced columns as (b, a), the name follows the key');
}

# PK (b, a), a -> x, b -> y: sorted by the referencing names this was (x, y)
# -> (a, b), a list no key has
{
  my $ddl = DBIO::MSSQL::DDL->install_ddl(schema_for('pkba2', ['b', 'a'], undef, $straight));
  like($ddl,
    qr/ADD CONSTRAINT FK_c_y_x FOREIGN KEY \(y, x\) REFERENCES p \(b, a\);/,
    'PK (b, a), a<-x b<-y: (y, x) -> (b, a); the name follows the foreign key');
}
{
  my $ddl = DBIO::MSSQL::DDL->install_ddl(schema_for('pkab2', ['a', 'b'], undef, $straight));
  like($ddl,
    qr/ADD CONSTRAINT FK_c_x_y FOREIGN KEY \(x, y\) REFERENCES p \(a, b\);/,
    'PK (a, b), a<-x b<-y: (x, y) -> (a, b)');
}

# PK (a, b): the pairs stay paired
{
  my $ddl = DBIO::MSSQL::DDL->install_ddl(schema_for('pkab', ['a', 'b'], undef, $swap));
  like($ddl,
    qr/ADD CONSTRAINT FK_c_y_x FOREIGN KEY \(y, x\) REFERENCES p \(a, b\);/,
    'PK (a, b): referenced (a, b), referencing (y, x) -- the pairs are kept');
}

# a unique constraint is a key to reference too
{
  my $ddl = DBIO::MSSQL::DDL->install_ddl(
    schema_for('uq', ['a'], { p_ba => ['b', 'a'] }, $swap));
  like($ddl, qr/FOREIGN KEY \(x, y\) REFERENCES p \(b, a\);/,
    'the unique constraint (b, a) is the key the foreign key follows');
}

# the primary key wins when a unique constraint over the same columns is in
# another order
{
  my $ddl = DBIO::MSSQL::DDL->install_ddl(
    schema_for('both', ['a', 'b'], { p_ba => ['b', 'a'] }, $swap));
  like($ddl, qr/FOREIGN KEY \(y, x\) REFERENCES p \(a, b\);/,
    'primary key (a, b) and unique (b, a): the primary key order is taken');
}

# a single column: name and statement as before
{
  my $ddl = DBIO::MSSQL::DDL->install_ddl(
    schema_for('one', ['a'], undef, { 'foreign.a' => 'self.x' }));
  like($ddl, qr/ADD CONSTRAINT FK_c_x FOREIGN KEY \(x\) REFERENCES p \(a\);/, 'one column unchanged');
}

# no key over exactly these columns: the old order (the server decides)
{
  my $ddl = DBIO::MSSQL::DDL->install_ddl(
    schema_for('nokey', ['a'], undef, $swap));
  like($ddl, qr/FOREIGN KEY \(x, y\) REFERENCES p \(b, a\);/,
    'no matching key: sorted by the referencing names, as before');
}

done_testing;
