use strict;
use warnings;
no warnings 'uninitialized';

use DBI;
use Data::Dumper;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];
use Storable qw/dclone/;

use constant N_DBI_MOCK_TESTS => 7;
use constant N_BASIC_TESTS    => 1;

use Test::More tests => (N_BASIC_TESTS + N_DBI_MOCK_TESTS);


# die_ok : succeeds if the supplied coderef dies with an exception
sub die_ok(&) { 
  my $code=shift; 
  eval {$code->()}; 
  my $err = $@;
  $err =~ s/ at .*//;
  ok($err, $err);
}



use_ok("DBIx::DataModel");

DBIx::DataModel->Schema('HR') # Human Resources
->Table(Employee   => T_Employee   => qw/emp_id/)
->Table(Department => T_Department => qw/dpt_id/)
->Table(Activity   => T_Activity   => qw/act_id/)
->Composition([qw/Employee   employee   1 /],
              [qw/Activity   activities * /])
->Association([qw/Department department 1 /],
              [qw/Activity   activities * /]);


SKIP: {
  eval "use DBD::Mock 1.36; 1"
    or skip "DBD::Mock 1.36 does not seem to be installed", N_DBI_MOCK_TESTS;

  my $dbh = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1, AutoCommit => 1});

  # sqlLike : takes a list of SQL regex and bind params, and a test msg.
  # Checks if those match with the DBD::Mock history.

  sub sqlLike { # closure on $dbh
                # TODO : fix line number, should report the caller's line
    my $msg = pop @_;

    for (my $hist_index = -(@_ / 2); $hist_index < 0; $hist_index++) {
      my ($sql, $bind)  = (shift, shift);
      my $hist = $dbh->{mock_all_history}[$hist_index];

      is_same_sql_bind($hist->statement, $hist->bound_params,
                       $sql,             $bind, "$msg [$hist_index]");
    }
    $dbh->{mock_clear_history} = 1;
  }

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


  my @tables = $schema->metadm->tables;
  my @names  = sort map {$_->name} @tables;
  is_deeply(\@names, [qw/Activity Department Employee/], "->tables method");
}


