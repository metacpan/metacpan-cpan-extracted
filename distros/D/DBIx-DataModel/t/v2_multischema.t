use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;
use Test::More;


# override the update method in one of the generated classes
package HR::Department;
use DBIx::DataModel::Meta::Utils qw/does/;

sub update {
  my $self      = shift;
  my $to_update = $_[-1];

  if (does($to_update, 'HASH')) {
    $to_update->{__UPDATE_METHOD} = 'was_overridden';
  }
  return $self->next::method(@_);
}

# back to main package
package main;


my $schema = HR->new(dbh => $dbh);

my $emp = $schema->table('Employee')->bless_from_DB({
  firstname => 'Joseph',
  lastname  => 'BODIN DE BOISMORTIER',
  d_birth   => '1775-12-16',
  emp_id    => 999,
});


my $connected_source = $schema->table('Employee');

my $statement = $connected_source->join(qw/activities department/);
$statement->refine(-where => {gender => 'F'});
$statement->refine(-where => {gender => {'!=' => 'M'}});
$statement->prepare;
my $row = $statement->execute($emp)->next;
sqlLike('SELECT * ' .
        'FROM T_Activity ' .
        'INNER JOIN T_Department ' .
        'ON T_Activity.dpt_id=T_Department.dpt_id ' .
        'WHERE (emp_id = ? AND gender = ? AND gender != ?)', [999, 'F', 'M'],
        'statement prepare/execute');


$emp->update;
sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ?, lastname = ? '
       .'WHERE emp_id = ?',
       ['1775-12-16', 'Joseph', 'BODIN DE BOISMORTIER', 999],
       'update object');

$connected_source->update(987, {firstname => 'Boudin'});
sqlLike('UPDATE T_Employee SET firstname = ? WHERE emp_id = ?',
       ['Boudin', 987],
       'update from class');

$connected_source->update(-set => {firstname => 'Boudin'},
                          -where => {emp_id => {'>' => 10}});
sqlLike('UPDATE T_Employee SET firstname = ? WHERE emp_id > ?',
       ['Boudin', 10],
       'bulk update');

is ($connected_source->metadm, $schema->db_table('T_Employee')->metadm,
    "db_table() - correct name");
ok (!$schema->db_table('foobar'),
    "db_table() - incorrect name");


# check that the overridden update() method is invoked
$schema->table('Department')->update(123, {foo => 'bar'});
sqlLike('UPDATE T_Department SET __UPDATE_METHOD = ?, foo = ? WHERE dpt_id = ?',
       ['was_overridden', 'bar', 123],
       'overridden update() method');


my @tables = $schema->metadm->tables;
my @names  = sort map {$_->name} @tables;
is_deeply(\@names, [qw/Activity Department Employee/], "->tables method");


done_testing;


