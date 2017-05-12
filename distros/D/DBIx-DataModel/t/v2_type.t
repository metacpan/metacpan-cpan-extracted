use strict;
use warnings;

use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use DBIx::DataModel -compatibility=> undef;

use constant NTESTS  => 2;
use Test::More tests => NTESTS;

DBIx::DataModel->Schema('HR') # Human Resources
->Table(Employee   => T_Employee   => qw/emp_id/);

HR->Type(Multival => 
  from_DB => sub {$_[0] = [split /;/, $_[0]]   if defined $_[0]},
  to_DB   => sub {$_[0] = join ";", @{$_[0]}   if defined $_[0]},
);

HR->Type(Upcase => 
  to_DB   => sub {$_[0] = uc($_[0])   if defined $_[0]},
);

my $meta_emp = HR->table('Employee')->metadm;

$meta_emp->define_column_type(Multival => qw/kids interests/);
$meta_emp->define_column_type(Upcase   => qw/interests/);


SKIP: {

  eval "use DBD::Mock 1.36; 1"
    or skip "DBD::Mock 1.36 does not seem to be installed", NTESTS;

  my $dbh = DBI->connect('DBI:Mock:', '', '', 
                         {RaiseError => 1, AutoCommit => 1});

  HR->dbh($dbh);

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

  my $emp_id = HR->table('Employee')->insert({
    firstname => 'Foo',
    kids      => [qw/Abel Barbara Cain Deborah Emily/],
    interests => [qw/Music Computers Sex/],
   });

  sqlLike("INSERT INTO T_Employee ( firstname, interests, kids)"
          . "VALUES ( ?, ?, ? )",
          [qw/Foo MUSIC;COMPUTERS;SEX Abel;Barbara;Cain;Deborah;Emily/],
          "insert with to_DB handlers");


  # test applying a type handler at the statement level
  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [[qw/computed_col/],
                                [qw/foo;bar/],
                                [qw/1;2;3/]];
  my $computed_col = HR->table('Employee')->select(
    -columns => ['CASE WHEN foo is NULL THEN bar ELSE buz END|computed_col'],
    -column_types => {
      Multival => ['computed_col'],
     },
    -result_as => 'flat_arrayref',
   );
  is_deeply($computed_col, [[qw/foo bar/], [qw/1 2 3/]], 
            'aliased computed col');
}


