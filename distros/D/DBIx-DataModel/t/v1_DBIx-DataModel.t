use strict;
use warnings;
no warnings 'uninitialized';

use DBI;
use Data::Dumper;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];
use Storable qw/dclone/;

use constant N_DBI_MOCK_TESTS => 108;
use constant N_BASIC_TESTS    =>  15;

use Test::More tests => (N_BASIC_TESTS + N_DBI_MOCK_TESTS);


# die_ok : succeeds if the supplied coderef dies with an exception
sub die_ok(&) { 
  my $code=shift; 
  eval {$code->()}; 
  my $err = $@;
  $err =~ s/ at .*//;
  ok($err, $err);
}



use_ok("DBIx::DataModel", -compatibility=> 1.0);

DBIx::DataModel->Schema('HR'); # Human Resources


ok(HR->isa("DBIx::DataModel::Schema"), 'Schema defined');
my ($lst, $emp, $emp2, $act);

# will not override an existing package
die_ok {DBIx::DataModel->Schema('DBI');};


  HR->Table(Employee   => T_Employee   => qw/emp_id/)
    ->Table(Department => T_Department => qw/dpt_id/)
    ->Table(Activity   => T_Activity   => qw/act_id/);


ok(HR::Employee->isa("DBIx::DataModel::Source::Table"), 'Table defined');
ok(HR::Employee->can("select"), 'select method defined');

  package HR::Department;
  sub currentEmployees {
    my $self = shift;
    my $currentAct = $self->activities({d_end => [{-is  => undef},
                                                  {"<=" => '01.01.2005'}]});
    return map {$_->employee} @$currentAct;
  }
  
  package main;		# switch back to the 'main' package


is_deeply([HR::Employee->primKey], ['emp_id'], 'primKey');

die_ok {HR::Employee->Table(Foo    => T_Foo => qw/foo_id/)};




  HR->Composition([qw/Employee   employee   1 /],
                  [qw/Activity   activities * /])
    ->Association([qw/Department department 1 /],
                  [qw/Activity   activities * /]);

ok(HR::Activity->can("employee"),   'Association 1');
ok(HR::Employee->can("activities"), 'Association 2');

  HR->View(MyView =>
     "DISTINCT column1 AS c1, t2.column2 AS c2",
     "Table1 AS t1 LEFT OUTER JOIN Table2 AS t2 ON t1.fk=t2.pk",
     {c1 => 'foo', c2 => {-like => 'bar%'}},
     qw/Employee Activity/);


ok(HR::MyView->isa("HR::Employee"), 'HR::MyView ISA HR::Employee'); 
ok(HR::MyView->isa("HR::Activity"), 'HR::MyView ISA HR::Activity'); 

ok(HR::MyView->can("employee"), 'View inherits roles');

  HR->ColumnType(Date => 
     fromDB   => sub {$_[0] =~ s/(\d\d\d\d)-(\d\d)-(\d\d)/$3.$2.$1/},
     toDB     => sub {$_[0] =~ s/(\d\d)\.(\d\d)\.(\d\d\d\d)/$3-$2-$1/},
     validate => sub {$_[0] =~ m/(\d\d)\.(\d\d)\.(\d\d\d\d)/});;

  HR::Employee->ColumnType(Date => qw/d_birth/);
  HR::Activity->ColumnType(Date => qw/d_begin d_end/);

  HR->NoUpdateColumns(qw/d_modif user_id/);
  HR::Employee->NoUpdateColumns(qw/last_login/);

is_deeply([sort HR::Employee->noUpdateColumns], 
	  [qw/d_modif last_login user_id/], 'noUpdateColumns');

  HR::Employee->ColumnHandlers(lastname => normalizeName => sub {
			    $_[0] =~ s/\w+/\u\L$&/g
			  });

  HR::Employee->AutoExpand(qw/activities/);

  $emp = HR::Employee->blessFromDB({firstname => 'Joseph',
                                    lastname  => 'BODIN DE BOISMORTIER',
                                    d_birth   => '1775-12-16'});
  $emp->applyColumnHandler('normalizeName');

is($emp->{d_birth}, '16.12.1775', 'fromDB handler');
is($emp->{lastname}, 'Bodin De Boismortier', 'ad hoc handler');


  # test self-referential assoc.
  HR->Association([qw/Employee   spouse   0..1 emp_id/],
                  [qw/Employee   ---      1    spouse_id/]);



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


  HR->dbh($dbh);
  isa_ok(HR->dbh, 'DBI::db', 'dbh handle');

  HR->dbh(undef);
  is(HR->dbh, undef, 'dbh handle was unset');

  HR->dbh($dbh);

  $lst = HR::Employee->select;
  sqlLike('SELECT * FROM T_Employee', [], 'empty select');

  $lst = HR::Employee->select(-for => 'read only');
  sqlLike('SELECT * FROM T_Employee FOR READ ONLY', [], 'for read only');


  $lst = HR::Employee->select([qw/firstname lastname emp_id/],
			  {firstname => {-like => 'D%'}});
  sqlLike('SELECT firstname, lastname, emp_id '.
	  'FROM T_Employee ' .
	  "WHERE (firstname LIKE ?)", ['D%'], 'like select');


  $lst = HR::Employee->select({firstname => {-like => 'D%'}});
  sqlLike('SELECT * '.
	  'FROM T_Employee ' .
	  "WHERE ( firstname LIKE ? )", ['D%'], 'implicit *');


  $lst = HR::Employee->select("firstname AS fn, lastname AS ln",
			  undef,
			  [qw/d_birth/]);

  sqlLike('SELECT firstname AS fn, lastname AS ln '.
	  'FROM T_Employee ' .
	  "ORDER BY d_birth", [], 'order_by select');


  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/ln  db/],
                                 [qw/foo 2001-01-01/], 
                                 [qw/bar 2002-02-02/] ];
  $lst = HR::Employee->select(-columns => [qw/lastname|ln d_birth|db/]);
  sqlLike('SELECT lastname AS ln, d_birth AS db '.
	  'FROM T_Employee', 
          [], 'column aliases');
  is($lst->[0]{db}, "01.01.2001", "fromDB handler on column alias");


  $lst = HR::Employee->select(-distinct => "lastname, firstname");

  sqlLike('SELECT DISTINCT lastname, firstname '.
	  'FROM T_Employee' , [], 'distinct 1');


  $lst = HR::Employee->select(-distinct => [qw/lastname firstname/]);

  sqlLike('SELECT DISTINCT lastname, firstname '.
	  'FROM T_Employee' , [], 'distinct 2');


  $lst = HR::Employee->select(-columns => ['lastname', 
				       'COUNT(firstname) AS n_emp'],
			  -groupBy => [qw/lastname/],
			  -having  => [n_emp => {">=" => 2}],
			  -orderBy => 'n_emp DESC'
			 );


  sqlLike('SELECT lastname, COUNT(firstname) AS n_emp '.
	  'FROM T_Employee '.
	  'GROUP BY lastname HAVING ((n_emp >= ?)) '.
	  'ORDER BY n_emp DESC', [2], 'group by');



  $lst = HR::Employee->select(-orderBy => [qw/+col1 -col2 +col3/]);
  sqlLike('SELECT * FROM T_Employee ORDER BY col1 ASC, col2 DESC, col3 ASC', 
          [], '-orderBy prefixes');



  $emp2 = HR::Employee->fetch(123);
  sqlLike('SELECT * FROM T_Employee WHERE (emp_id = ?)', 
          [123], 'fetch');

  $emp2 = HR::Employee->select(-fetch => 123);
  sqlLike('SELECT * FROM T_Employee WHERE (emp_id = ?)', 
          [123], 'select(-fetch)');

  $emp2 = HR::Employee->fetch("");
  sqlLike('SELECT * FROM T_Employee WHERE (emp_id = ?)', 
          [""], 'fetch (empty string)');


  die_ok {$emp2 = HR::Employee->fetch(undef)};


  # successive calls to fetch_cached 
  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/foo bar/], [123, 456] ];
  $emp2 = HR::Employee->fetch_cached(123);
  is (@{$dbh->{mock_all_history}}, 1, "first fetch_cached : go to db");
  my $emp3 = HR::Employee->fetch_cached(123);
  is (@{$dbh->{mock_all_history}}, 1, "second fetch_cached : no db");
  is_deeply($emp3, {foo=>123, bar=>456}, "fetch_cached result");

  $emp->{emp_id} = 999;

  # method call should break without autoload
die_ok {$emp->emp_id};
  # now turn it on
  HR->Autoload(1);
is($emp->emp_id, 999, 'autoload schema');
  # turn it off again
  HR->Autoload(0);
die_ok {$emp->emp_id};
  # turn it on just for the Employee class
  HR::Employee->Autoload(1);
is($emp->emp_id, 999, 'autoload table');
  # turn it off again
  HR::Employee->Autoload(0);
die_ok {$emp->emp_id};

  $lst = $emp->activities;

  sqlLike('SELECT * ' .
	  'FROM T_Activity ' .
	  "WHERE ( emp_id = ? )", [999], 'activities');


  $lst = $emp->activities([qw/d_begin d_end/]);

  sqlLike('SELECT d_begin, d_end ' .
	  'FROM T_Activity ' .
	  "WHERE ( emp_id = ? )", [999], 'activities column list');


  $lst = $emp->activities({d_begin => {">=" => '2000-01-01'}});

  sqlLike('SELECT * ' .
	  'FROM T_Activity ' .
	  "WHERE (d_begin >= ? AND emp_id = ?)", ['2000-01-01', 999], 
	    'activities where criteria');

  
  $lst = $emp->activities("d_begin AS db, d_end AS de", 
                          {}, 
                          [qw/d_begin d_end/]);

  sqlLike('SELECT d_begin AS db, d_end AS de ' .
	  'FROM T_Activity ' .
	  "WHERE (emp_id = ?) ".
	  'ORDER BY d_begin, d_end', [999], 
	    'activities order by');

  $act = $emp->activities(-fetch => 123);
  sqlLike('SELECT * FROM T_Activity WHERE (act_id = ? AND emp_id = ? )', 
          [123, 999], 'activities(-fetch)');


  # testing cached expanded values
  $emp->{activities} = "foo";
  is ($emp->activities, "foo", "cached expanded values");
  delete $emp->{activities};


  # empty foreign key
  my $fake_emp = bless {}, 'HR::Employee';
  die_ok {$fake_emp->activities()};

  # unbless
 SKIP: {
    eval "use Acme::Damn; 1"
      or skip "Acme::Damn does not seem to be installed", 1;

    my $emp2 = HR::Employee->blessFromDB({
      emp_id => 999,
      activities => [map {HR::Activity->blessFromDB({foo => $_})} 1..3],
      spouse     => HR::Employee->blessFromDB({foo => 'spouse'}),
    });
    is_deeply(HR->unbless($emp2),
              {emp_id => 999, 
               spouse => {foo => 'spouse'},
               activities => [{foo => 1}, {foo => 2}, {foo => 3}]}, 
              "unbless");
  }


  # testing combination of where criteria
  my $statement = HR::Employee->activities(-where => {foo => [3, 4]});
  $act = $statement->bind($emp)
                   ->select(-where => {foo => [4, 5]});

  sqlLike('SELECT * FROM T_Activity '
          .  'WHERE ( emp_id = ? AND ( (     foo = ? OR foo = ? ) '
          .                           'AND ( foo = ? OR foo = ? )))',
          [999, 3, 4, 4, 5], "combined where");

  $statement = HR::Employee->activities(-where => [foo => "bar", bar => "foo"]);
  $act = $statement->bind($emp)
                   ->select(-where => [foobar => 123, barfoo => 456]);

  sqlLike('SELECT * FROM T_Activity '
          .  'WHERE ( (     (foo = ?  OR bar = ?) '
          .            'AND (foobar = ? OR barfoo = ?)'
          .          ') AND emp_id = ? )',
          [qw/bar foo 123 456 999/], "combined where, arrayrefs");


  # select with OR through an arrayref
  my $result = HR::Employee->select(-where => [foo => 1, bar => 2]);
  sqlLike('SELECT * FROM T_Employee WHERE foo = ? OR bar = ?',
          [qw/1 2/], "where arrayref, OR");

  # select -resultAs => 'flat_arrayref'
  SKIP : {
    $DBD::Mock::VERSION >= 1.39
      or skip "need DBD::Mock 1.39 or greater", 2;

    my @fake_rs = ([qw/col1 col2/], [qw/foo1 foo2/], [qw/bar1 bar2/]);
    $dbh->{mock_clear_history} = 1;
    $dbh->{mock_add_resultset} = \@fake_rs;

    my $pairs = HR::Employee->select(-columns  => [qw/col1 col2/],
                                     -resultAs => 'flat_arrayref');
    is_deeply($pairs, [qw/foo1 foo2 bar1 bar2/], "resultAs => 'flat_arrayref'");

    $dbh->{mock_clear_history} = 1;
    $dbh->{mock_add_resultset} = [map {[reverse @$_]} @fake_rs];
    $pairs = HR::Employee->select(-columns  => [qw/col2 col1/],
                                  -resultAs => 'flat_arrayref');
    is_deeply($pairs, [qw/foo2 foo1 bar2 bar1/], "resultAs => 'flat_arrayref'");
  }


  # select -resultAs => 'hashref'
  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/emp_id foo/],
                                 [qw/1 1/], 
                                 [qw/2 2/],
                                 [qw/1 1bis/],
                                ];
  my $hashref = HR::Employee->select(
    -resultAs => 'hashref'
   );
  is_deeply($hashref, {1 => {emp_id => 1, foo => '1bis'},
                       2 => {emp_id => 2, foo => 2}},
              "resultAs => 'hashref'");

  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/emp_id foo/],
                                 [qw/1 1/], 
                                 [qw/2 2/],
                                 [qw/1 1bis/],
                                ];
  $hashref = HR->join(qw/Employee activities/)->select(
    -resultAs => [hashref => qw/emp_id foo/],
   );
  is_deeply($hashref, {1 => {1      => {emp_id => 1, foo => 1},
                             '1bis' => {emp_id => 1, foo => '1bis'}},
                       2 => {2      => {emp_id => 2, foo => 2}}},
              'resultAs => [hashref => @cols]');

  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/emp_id act_id/],
                                 [qw/1 1/], 
                                 [qw/2 2/],
                                 [qw/1 1bis/],
                                ];

  SKIP: {
    skip "THINK: semantics of ->primary_key for a join", 1;
    $hashref = HR->join(qw/Employee activities/)->select(
      -resultAs => 'hashref'
     );
    is_deeply($hashref, {1 => {1      => {emp_id => 1, act_id => 1},
                               '1bis' => {emp_id => 1, act_id => '1bis'}},
                         2 => {2      => {emp_id => 2, act_id => 2}}},
                'resultAs => "hashref"');
  };


  # subquery
  my $subquery = HR::Employee->select(
    -columns  => 'emp_id',
    -where    => {d_birth => {-between => [1950, 1980]}},
    -resultAs => 'subquery',
   );
  $act = HR::Activity->select(-where => {emp_id => {-not_in => $subquery}});
  sqlLike('SELECT * FROM T_Activity WHERE emp_id NOT IN '
            . '(SELECT emp_id FROM T_Employee WHERE d_birth BETWEEN ? AND ?)',
          [1950, 1980],
         'subquery');

  # plain insertion using arrayref syntax
  my ($bach_id, $berlioz_id, $monteverdi_id) = 
    HR::Employee->insert([qw/ firstname    lastname   /],
                         [qw/ Johann       Bach       /],
                         [qw/ Hector       Berlioz    /],
                         [qw/ Claudio      Monteverdi /]);
  my $insert_sql = 'INSERT INTO T_Employee (firstname, lastname) VALUES (?, ?)';
  sqlLike($insert_sql, [qw/ Johann       Bach       /],
          $insert_sql, [qw/ Hector       Berlioz    /],
          $insert_sql, [qw/ Claudio      Monteverdi /],
          'insert with arrayref syntax');

  # insertion into related class
  $emp->insert_into_activities({d_begin =>'2000-01-01', d_end => '2000-02-02'});
  sqlLike('INSERT INTO T_Activity (d_begin, d_end, emp_id) ' .
            'VALUES (?, ?, ?)', ['2000-01-01', '2000-02-02', 999],
	    'add_to_activities');


  # test cascaded inserts
  my $tree = {firstname  => "Johann Sebastian",  
              lastname   => "Bach",
              activities => [{d_begin  => '01.01.1707',
                              d_end    => '01.07.1720',
                              dpt_code => 'Maria-Barbara'},
                             {d_begin  => '01.12.1721',
                              d_end    => '18.07.1750',
                              dpt_code => 'Anna-Magdalena'}]};


  my $emp_id = HR::Employee->insert(dclone($tree));
  my $sql_insert_activity = 'INSERT INTO T_Activity (d_begin, d_end, '
                          . 'dpt_code, emp_id) VALUES (?, ?, ?, ?)';

  sqlLike('INSERT INTO T_Employee (firstname, lastname) VALUES (?, ?)',
          ["Johann Sebastian", "Bach"],
          $sql_insert_activity, 
          ['1707-01-01', '1720-07-01', 'Maria-Barbara', $emp_id],
          $sql_insert_activity, 
          ['1721-12-01', '1750-07-18', 'Anna-Magdalena', $emp_id],
          "cascaded insert");

  # test the -returning => {} option
  $dbh->{mock_start_insert_id} = 10;
  $result   = HR::Employee->insert(dclone($tree), -returning => {});
  my $expected = { emp_id     => 10, 
                   activities => [{act_id => 11}, {act_id => 12}]};
  is_deeply($result, $expected,  "results from -returning => {}");

  # insert with literal SQL
  $emp_id = HR::Employee->insert({
    birthdate  => \["TO_DATE(?, 'DD.MM.YYYY')", "10.09.1659"],
    firstname  => "Henry",
    lastname   => "Purcell",
   });
  sqlLike( q[INSERT INTO T_Employee (birthdate, firstname, lastname) ]
          .q[VALUES (TO_DATE(?, 'DD.MM.YYYY'), ?, ?)],
          ["10.09.1659", "Henry", "Purcell"],
          "insert with SQL function");

  HR::MyView->select({c3 => 22});

  sqlLike('SELECT DISTINCT column1 AS c1, t2.column2 AS c2 ' .
	  'FROM Table1 AS t1 LEFT OUTER JOIN Table2 AS t2 '.
	  'ON t1.fk=t2.pk ' .
	  'WHERE (c1 = ? AND c2 LIKE ? AND c3 = ?)',
	     ['foo', 'bar%', 22], 'HR::MyView');

  my $view = HR->join(qw/Employee activities department/);
  $view->select("lastname, dpt_name", {gender => 'F'});

  sqlLike('SELECT lastname, dpt_name ' .
	  'FROM T_Employee LEFT OUTER JOIN T_Activity ' .
	  'ON T_Employee.emp_id=T_Activity.emp_id ' .
	  'LEFT OUTER JOIN T_Department ' .
	  'ON T_Activity.dpt_id=T_Department.dpt_id ' .
	  'WHERE (gender = ?)',
             ['F'], 'join');


  my $view2 = HR->join(qw/Employee <=> activities => department/);
  $view2->select("lastname, dpt_name", {gender => 'F'});

  sqlLike('SELECT lastname, dpt_name ' .
	  'FROM T_Employee INNER JOIN T_Activity ' .
	  'ON T_Employee.emp_id=T_Activity.emp_id ' .
	  'LEFT OUTER JOIN T_Department ' .
	  'ON T_Activity.dpt_id=T_Department.dpt_id ' .
	  'WHERE (gender = ?)', ['F'], 'join with explicit roles');




  my $view3 = HR->join(qw/Activity employee department/);
  $view3->select("lastname, dpt_name", {gender => 'F'});

  sqlLike('SELECT lastname, dpt_name ' .
	  'FROM T_Activity INNER JOIN T_Employee ' .
	  'ON T_Activity.emp_id=T_Employee.emp_id ' .
	  'INNER JOIN T_Department ' .
	  'ON T_Activity.dpt_id=T_Department.dpt_id ' .
	  'WHERE (gender = ?)', ['F'], 'join with indirect role');


  die_ok {$emp->join(qw/activities foo/)};
  die_ok {$emp->join(qw/foo bar/)};



  # join from an instance
  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/act_id  dpt_id/],
                                 [qw/111     222   /],  ];
  my $act_dpt = $emp->join(qw/activities department/)
                    ->select({gender => 'F'});
  sqlLike('SELECT * ' .
	  'FROM T_Activity ' .
	  'INNER JOIN T_Department ' .
	  'ON T_Activity.dpt_id=T_Department.dpt_id ' .
	  'WHERE (emp_id = ? AND gender = ?)', [999, 'F'], 
	  'join (instance method)');

  # re-join back from that instance
  $act_dpt->[0]->join(qw/activities employee/)->select();
  sqlLike('SELECT * ' .
	  'FROM T_Activity ' .
	  'INNER JOIN T_Employee ' .
	  'ON T_Activity.emp_id=T_Employee.emp_id ' .
	  'WHERE (dpt_id = ?)', 
          [222], 'join (instance method) from a previous join');

  # table aliases
  HR->join(qw/Activity|act employee|emp department|dpt/)
    ->select(-columns => [qw/lastname dpt_name/], 
             -where   => {gender => 'F'});

  sqlLike('SELECT lastname, dpt_name ' .
	  'FROM T_Activity AS act INNER JOIN T_Employee AS emp ' .
	  'ON act.emp_id=emp.emp_id ' .
	  'INNER JOIN T_Department AS dpt ' .
	  'ON act.dpt_id=dpt.dpt_id ' .
	  'WHERE (gender = ?)', ['F'], 'table aliases');

  # explicit sources
  HR->join(qw/Activity Activity.employee Activity.department/)
    ->select(-columns => [qw/lastname dpt_name/], 
             -where   => {gender => 'F'});

  sqlLike('SELECT lastname, dpt_name ' .
	  'FROM T_Activity INNER JOIN T_Employee ' .
	  'ON T_Activity.emp_id=T_Employee.emp_id ' .
	  'INNER JOIN T_Department ' .
	  'ON T_Activity.dpt_id=T_Department.dpt_id ' .
	  'WHERE (gender = ?)', ['F'], 'explicit sources');


  # both table aliases and explicit sources
  HR->join(qw/Activity|act act.employee|emp act.department|dpt/)
    ->select(-columns => [qw/lastname dpt_name/], 
             -where   => {gender => 'F'});

  sqlLike('SELECT lastname, dpt_name ' .
	  'FROM T_Activity AS act INNER JOIN T_Employee AS emp ' .
	  'ON act.emp_id=emp.emp_id ' .
	  'INNER JOIN T_Department AS dpt ' .
	  'ON act.dpt_id=dpt.dpt_id ' .
	  'WHERE (gender = ?)', ['F'], 
          'both table aliases and explicit sources');


  HR->join(qw/Department|dpt dpt.activities|act act.employee|emp/)
    ->select(-columns => [qw/lastname dpt_name/], 
             -where   => {gender => 'F'});
  sqlLike('SELECT lastname, dpt_name ' .
	  'FROM T_Department AS dpt '.
	  'LEFT OUTER JOIN T_Activity AS act ' .
	  'ON dpt.dpt_id=act.dpt_id ' .
          'LEFT OUTER JOIN T_Employee AS emp ' .
	  'ON act.emp_id=emp.emp_id ' .
	  'WHERE (gender = ?)', ['F'], 
          'both table aliases and explicit sources, reversed');

  # column types on table and column aliases
  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/ln  db/],
                                 [qw/foo 2001-01-01/], 
                                 [qw/bar 2002-02-02/] ];
  $lst = HR->join(qw/Department|dpt dpt.activities|act act.employee|emp/)
           ->select(-columns => [qw/emp.lastname|ln emp.d_birth|db/], 
                    -where   => {gender => 'F'});
  sqlLike('SELECT emp.lastname AS ln, emp.d_birth AS db ' .
	  'FROM T_Department AS dpt '.
	  'LEFT OUTER JOIN T_Activity AS act ' .
	  'ON dpt.dpt_id=act.dpt_id ' .
          'LEFT OUTER JOIN T_Employee AS emp ' .
	  'ON act.emp_id=emp.emp_id ' .
	  'WHERE (gender = ?)', ['F'], 
          'column types on table and column aliases (sql)');
  is($lst->[0]{db}, "01.01.2001", "fromDB handler on table and column alias");


  # column types on column aliases, without table alias
  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/ln  db/],
                                 [qw/foo 2001-01-01/], 
                                 [qw/bar 2002-02-02/] ];

  $lst = HR->join(qw/Department|dpt dpt.activities|act act.employee/)
           ->select(-columns => [qw/T_Employee.lastname|ln 
                                    T_Employee.d_birth|db/],
                    -where   => {gender => 'F'});
  sqlLike('SELECT T_Employee.lastname AS ln, T_Employee.d_birth AS db ' .
	  'FROM T_Department AS dpt '.
	  'LEFT OUTER JOIN T_Activity AS act ' .
	  'ON dpt.dpt_id=act.dpt_id ' .
          'LEFT OUTER JOIN T_Employee ' .
	  'ON act.emp_id=T_Employee.emp_id ' .
	  'WHERE (gender = ?)', 
          ['F'], 
          'column types on column aliases, without table alias');
  is($lst->[0]{db}, "01.01.2001", 
     "fromDB handler on column alias, without table alias");


  # aliases on computed columns
  $dbh->{mock_clear_history} = 1;
  $dbh->{mock_add_resultset} = [ [qw/fmt1       fmt2       sub/],
                                 [qw/2001-01-01 2001-01-01 1234/] ];
  $lst = HR->join(qw/Department|dpt dpt.activities|act act.employee|emp/)
           ->select(-columns => [
    "to_char(d_birth,'format')|fmt1",
    "to_char(emp.d_birth,'format')|fmt2",
    "(select count(*) from subt where subt.emp_id=emp.emp_id)|sub",
                                ]);
  sqlLike("SELECT to_char(d_birth,'format') AS fmt1, "
         ."to_char(emp.d_birth,'format') AS fmt2, "
         ."(select count(*) from subt where subt.emp_id=emp.emp_id) AS sub "
         ."FROM T_Department AS dpt "
         ."LEFT OUTER JOIN T_Activity AS act ON ( dpt.dpt_id = act.dpt_id ) "
         ."LEFT OUTER JOIN T_Employee AS emp ON ( act.emp_id = emp.emp_id )",
          [],
          'aliases on computed columns');
  is($lst->[0]{fmt1}, "2001-01-01", "fmt1, no col handler applied");
  is($lst->[0]{fmt2}, "2001-01-01", "fmt2, no col handler applied");
  is($lst->[0]{sub},  1234,         "sub,  no col handler applied");


  # stepwise statement prepare/execute
  $statement = HR::Employee->join(qw/activities department/);
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


  # many-to-many association

  HR->Association([qw/Employee   employees   * activities employee/],
			[qw/Department departments * activities department/]);

  my $dpts = $emp->departments(-where =>{gender => 'F'});
  sqlLike('SELECT * ' .
	  'FROM T_Activity ' .
	  'INNER JOIN T_Department ' .
	  'ON T_Activity.dpt_id=T_Department.dpt_id ' .
	  'WHERE (emp_id = ? AND gender = ?)', [999, 'F'], 
	  'N-to-N Association ');


  my $dpt = bless {dpt_id => 123}, 'HR::Department';
  my $empls = $dpt->employees;
  sqlLike('SELECT * ' .
	  'FROM T_Activity ' .
	  'INNER JOIN T_Employee ' .
	  'ON T_Activity.emp_id=T_Employee.emp_id ' .
	  'WHERE (dpt_id = ?)', [123], 
	  'N-to-N Association 2 ');




  HR::Employee->update(999, {firstname => 'toto', 
                             d_modif => '02.09.2005',
                             d_birth => '01.01.1950',
                             last_login => '01.09.2005'});

  sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ? '.
	  'WHERE (emp_id = ?)', ['1950-01-01', 'toto', 999], 'update');


  HR::Employee->update(     {firstname => 'toto', 
			 d_modif => '02.09.2005',
			 d_birth => '01.01.1950',
			 last_login => '01.09.2005',
			 emp_id => 999});

  sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ? '.
	  'WHERE (emp_id = ?)', ['1950-01-01', 'toto', 999], 'update2');


  $emp->{firstname}  = 'toto'; 
  $emp->{d_modif}    = '02.09.2005';
  $emp->{d_birth}    = '01.01.1950';
  $emp->{last_login} = '01.09.2005';

  my %emp2 = %$emp;

  $emp->update;

  sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ?, lastname = ? '.
	  'WHERE (emp_id = ?)', 
	  ['1950-01-01', 'toto', 'Bodin De Boismortier', 999], 'update3');


  HR->AutoUpdateColumns( last_modif => 
    sub{"someUser, someTime"}
  );
  HR::Employee->update(\%emp2);
  sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ?, ' .
	    'last_modif = ?, lastname = ? WHERE (emp_id = ?)', 
	  ['1950-01-01', 'toto', "someUser, someTime", 
	   'Bodin De Boismortier', 999], 'autoUpdate');


  HR->AutoInsertColumns( created_by => 
    sub{"firstUser, firstTime"}
  );

  HR::Employee->insert({firstname => "Felix",
                    lastname  => "Mendelssohn"});

  sqlLike('INSERT INTO T_Employee (created_by, firstname, last_modif, lastname) ' .
            'VALUES (?, ?, ?, ?)',
	  ['firstUser, firstTime', 'Felix', 'someUser, someTime', 'Mendelssohn'],
          'autoUpdate / insert');


  $emp = HR::Employee->blessFromDB({emp_id => 999});
  $emp->delete;
  sqlLike('DELETE FROM T_Employee '.
	  'WHERE (emp_id = ?)', [999], 'delete');


  $emp = HR::Employee->blessFromDB({emp_id => 999, spouse_id => 888});
  my $emp_spouse = $emp->spouse;
  sqlLike('SELECT * ' .
	  'FROM T_Employee ' .
	  "WHERE ( emp_id = ? )", [888], 'spouse self-ref assoc.');


  # testing -preExec / -postExec
  my %check_callbacks;
  HR::Employee->select(-where => {foo=>'bar'},
		   -preExec => sub {$check_callbacks{pre} = "was called"},
		   -postExec => sub {$check_callbacks{post} = "was called"},);
  is_deeply(\%check_callbacks, {pre =>"was called", 
				post => "was called" }, 'select, pre/post callbacks');

  %check_callbacks = ();
  HR::Employee->fetch(1234, {-preExec => sub {$check_callbacks{pre} = "was called"},
			 -postExec => sub {$check_callbacks{post} = "was called"}});
  is_deeply(\%check_callbacks, {pre =>"was called", 
				post => "was called" }, 'fetch, pre/post callbacks');


  # testing transactions 

  my $ok_trans       = sub { return "scalar transaction OK"     };
  my $ok_trans_array = sub { return qw/array transaction OK/    };
  my $fail_trans     = sub { die "failed transaction"           };
  my $nested_1       = sub { HR->doTransaction($ok_trans) };
  my $nested_many    = sub {
    my $r1 = HR->doTransaction($nested_1);
    my @r2 = HR->doTransaction($ok_trans_array);
    return ($r1, @r2);
  };

  is (HR->doTransaction($ok_trans), 
      "scalar transaction OK",
      "scalar transaction");
  sqlLike('BEGIN WORK', [], 
          'COMMIT',     [], "scalar transaction commit");

  is_deeply ([HR->doTransaction($ok_trans_array)],
             [qw/array transaction OK/],
             "array transaction");
  sqlLike('BEGIN WORK', [], 
          'COMMIT',     [], "array transaction commit");

  die_ok {HR->doTransaction($fail_trans)};
  sqlLike('BEGIN WORK', [], 
          'ROLLBACK',   [], "fail transaction rollback");

  $dbh->do('FAKE SQL, HISTORY MARKER');
  is_deeply ([HR->doTransaction($nested_many)],
             ["scalar transaction OK", qw/array transaction OK/],
             "nested transaction");
  sqlLike('FAKE SQL, HISTORY MARKER', [],
          'BEGIN WORK', [], 
          'COMMIT',     [], "nested transaction commit");


  # transaction object
  eval {HR->doTransaction($fail_trans)};
  my $err = $@;
  like ($err->initial_error, qr/^failed transaction/, "initial_error");
  is_deeply([$err->rollback_errors], [], "rollback_errors");


  # nested transactions on two different databases
  $dbh->{private_id} = "dbh1";
  my $other_dbh = DBI->connect('DBI:Mock:', '', '', 
                               {private_id => "dbh2", RaiseError => 1});

  $emp_id = 66;
  my $tell_dbh_id = sub {my $db_id = HR->dbh->{private_id};
                         HR::Employee->update({emp_id => $emp_id++, name => $db_id});
                         return "transaction on $db_id" };


  my $nested_change_dbh = sub {
    my $r1 = HR->doTransaction($tell_dbh_id);
    my $r2 = HR->doTransaction($tell_dbh_id, $other_dbh);
    my $r3 = HR->doTransaction($tell_dbh_id);
    return ($r1, $r2, $r3);
  };

  $dbh      ->do('FAKE SQL, BEFORE TRANSACTION');
  $other_dbh->do('FAKE SQL, BEFORE TRANSACTION');

  is_deeply ([HR->doTransaction($nested_change_dbh)],
             ["transaction on dbh1", 
              "transaction on dbh2", 
              "transaction on dbh1"],
              "nested transaction, change dbh");


  my $upd = 'UPDATE T_Employee SET last_modif = ?, name = ? WHERE ( emp_id = ? )';
  my $last_modif = 'someUser, someTime';

  sqlLike('FAKE SQL, BEFORE TRANSACTION', [],
          'BEGIN WORK', [], 
          $upd, [$last_modif, "dbh1", 66], 
          $upd, [$last_modif, "dbh1", 68], 
          'COMMIT',     [], "nested transaction on dbh1");


  $dbh = $other_dbh;
  sqlLike('FAKE SQL, BEFORE TRANSACTION', [],
          'BEGIN WORK', [], 
          $upd, [$last_modif, "dbh2", 67], 
          'COMMIT',     [], "nested transaction on dbh2");
} # END OF SKIP BLOCK



__END__

TODO: 

hasInvalidFields
expand
autoExpand
document the tests !!
select(-dbi_prepare_method => ..)

