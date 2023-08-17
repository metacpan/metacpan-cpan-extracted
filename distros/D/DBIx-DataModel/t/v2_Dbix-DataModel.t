use strict;
use warnings;
no warnings 'uninitialized';
use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;
use Clone qw/clone/;
use Test::More;

# Note : schema 'HR' with a few tables and associations is defined in DBIDM_Test


# general-purpose variables
my ($lst, $emp, $emp2, $act);


# additional association to test self-referential assoc.
HR->Association([qw/Employee   spouse   0..1 emp_id/],
                [qw/Employee   ---      1    spouse_id/]);


# connection to the mock database
HR_connect();


#----------------------------------------------------------------------
# test schema definitions
#----------------------------------------------------------------------

# proper schema definition
isa_ok 'HR', "DBIx::DataModel::Schema";

# will not override an existing package
die_ok {DBIx::DataModel->Schema('DBI')};

# proper class and method for a table
isa_ok 'HR::Employee', "DBIx::DataModel::Source::Table";
can_ok 'HR::Employee', "select";

# can't define a table on another table
die_ok {HR::Employee->Table(Foo    => T_Foo => qw/foo_id/)};

# primary_key method works
is_deeply([HR::Employee->primary_key], ['emp_id'], 'primary_key (perl class method)');
is_deeply([HR->table('Employee')->primary_key], ['emp_id'], 'primary_key (DBIDM class method)');


# path methods are present
can_ok 'HR::Activity', "employee";
can_ok 'HR::Employee',  "activities";


# legacy syntax : options as hash instead of hashref
DBIx::DataModel->Schema('HR2', 
  no_update_columns            => {d_modif => 1, user_id => 1},
  sql_no_inner_after_left_join => 1,
);
isa_ok 'HR2', 'DBIx::DataModel::Schema', 'options as hash';


#----------------------------------------------------------------------
# test View
#----------------------------------------------------------------------

# view definition
HR->View(MyView => "DISTINCT column1 AS c1, t2.column2 AS c2",
                   "Table1 AS t1 LEFT OUTER JOIN Table2 AS t2 ON t1.fk=t2.pk",
                   {c1 => 'foo', c2 => {-like => 'bar%'}},
                   qw/Employee Activity/);

# inheritance
isa_ok 'HR::MyView', "HR::Employee";
isa_ok 'HR::MyView', "HR::Activity";

# methods
can_ok 'HR::MyView', "employee";

# select()
HR::MyView->select(-where => {c3 => 22});
sqlLike('SELECT DISTINCT column1 AS c1, t2.column2 AS c2 ' .
        'FROM Table1 AS t1 LEFT OUTER JOIN Table2 AS t2 '.
        'ON t1.fk=t2.pk ' .
        'WHERE (c1 = ? AND c2 LIKE ? AND c3 = ?)',
           ['foo', 'bar%', 22], 'HR::MyView');

#----------------------------------------------------------------------
# test many-to-many association
#----------------------------------------------------------------------

HR->Association([qw/Employee   employees   * activities employee/],
      		[qw/Department departments * activities department/]);

$emp = HR::Employee->bless_from_DB({emp_id => 999});

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




#----------------------------------------------------------------------
# test types and handlers
#----------------------------------------------------------------------

HR->Type(Date => 
   from_DB   => sub {$_[0] =~ s/(\d\d\d\d)-(\d\d)-(\d\d)/$3.$2.$1/},
   to_DB     => sub {$_[0] =~ s/(\d\d)\.(\d\d)\.(\d\d\d\d)/$3-$2-$1/},
   validate  => sub {$_[0] =~ m/(\d\d)\.(\d\d)\.(\d\d\d\d)/});;

HR::Employee->metadm->define_column_type(Date => qw/d_birth/);
HR::Activity->metadm->define_column_type(Date => qw/d_begin d_end/);

my %no_upd = HR::Employee->metadm->no_update_column;
is_deeply([sort keys %no_upd], 
	  [qw/d_modif last_login user_id/], 'noUpdateColumns');

HR::Employee->metadm->define_column_handlers(lastname => normalizeName => sub {
                                               $_[0] =~ s/\w+/\u\L$&/g
                                             });

HR::Employee->metadm->define_auto_expand(qw/activities/);

$emp = HR::Employee->bless_from_DB({firstname => 'Joseph',
                                    lastname  => 'BODIN DE BOISMORTIER',
                                    d_birth   => '1775-12-16'});
$emp->apply_column_handler('normalizeName');

is($emp->{d_birth}, '16.12.1775', 'fromDB handler');
is($emp->{lastname}, 'Bodin De Boismortier', 'ad hoc handler');

# multiple types on same column
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
HR->table('Employee')->insert({
    firstname => 'Foo',
    kids      => [qw/Abel Barbara Cain Deborah Emily/],
    interests => [qw/Music Computers Sex/],
   });

sqlLike("INSERT INTO T_Employee ( firstname, interests, kids) VALUES ( ?, ?, ? )",
        [qw/Foo MUSIC;COMPUTERS;SEX Abel;Barbara;Cain;Deborah;Emily/],
        "insert with to_DB handlers");


# type handler at the statement level
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



#----------------------------------------------------------------------
# test general schema methods
#----------------------------------------------------------------------


# dbh method
isa_ok(HR->dbh, 'DBI::db');
HR->dbh(undef);
is(HR->dbh, undef, 'dbh handle was unset');
HR->dbh($dbh);


# unbless
$emp2 = HR::Employee->bless_from_DB({
  emp_id => 999,
  activities => [map {HR::Activity->bless_from_DB({foo => $_})} 1..3],
  spouse     => HR::Employee->bless_from_DB({foo => 'spouse'}),
});
is_deeply(HR->unbless($emp2),
          {emp_id => 999,
           spouse => {foo => 'spouse'},
           activities => [{foo => 1}, {foo => 2}, {foo => 3}]},
          "unbless");


#----------------------------------------------------------------------
# test select()
#----------------------------------------------------------------------

# plain select
$lst = HR::Employee->select;
sqlLike('SELECT * FROM T_Employee', [], 'empty select');

# -for clause
$lst = HR::Employee->select(-for => 'read only');
sqlLike('SELECT * FROM T_Employee FOR READ ONLY', [], 'for read only');

# -columns and -where clauses
$lst = HR::Employee->select(
  -columns => [qw/firstname lastname emp_id/],
  -where   => {firstname => {-like => 'D%'}},
 );
sqlLike('SELECT firstname, lastname, emp_id '.
        'FROM T_Employee ' .
        "WHERE (firstname LIKE ?)", ['D%'], 'like select');

# - implicit columns
$lst = HR::Employee->select(-where => {firstname => {-like => 'D%'}});
sqlLike('SELECT * '.
        'FROM T_Employee ' .
        "WHERE ( firstname LIKE ? )", ['D%'], 'implicit *');


# column aliases and -order_by clause
$lst = HR::Employee->select(-columns  => [qw/firstname|fn lastname|ln/],
                            -order_by => [qw/d_birth/]);
sqlLike('SELECT firstname AS fn, lastname AS ln '.
        'FROM T_Employee ' .
        "ORDER BY d_birth", [], 'order_by select');

# handlers on column aliases
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = [ [qw/ln  db/],
                               [qw/foo 2001-01-01/], 
                               [qw/bar 2002-02-02/] ];
$lst = HR::Employee->select(-columns => [qw/lastname|ln d_birth|db/]);
sqlLike('SELECT lastname AS ln, d_birth AS db '.
        'FROM T_Employee', 
        [], 'column aliases');
is($lst->[0]{db}, "01.01.2001", "fromDB handler on column alias");


# SQL function with dots (RT#104856)
HR::Employee->select(
  -columns   => 'DMBS_LOB.SUBSTR(col,200,1)|substr',
 );
sqlLike('SELECT DMBS_LOB.SUBSTR(col,200,1) AS substr FROM T_employee',
        [],
        'dot in function name');

# -distinct columns
$lst = HR::Employee->select(-columns => [-distinct => "lastname, firstname"]);
sqlLike('SELECT DISTINCT lastname, firstname '.
        'FROM T_Employee' , [], 'distinct 1');
$lst = HR::Employee->select(-columns => [-distinct => qw/lastname firstname/]);
sqlLike('SELECT DISTINCT lastname, firstname '.
        'FROM T_Employee' , [], 'distinct 2');

# -group_by / -having
$lst = HR::Employee->select(
  -columns  => ['lastname', 'COUNT(firstname) AS n_emp'],
  -group_by => [qw/lastname/],
  -having   => [n_emp => {">=" => 2}],
  -order_by => 'n_emp DESC'
 );
sqlLike('SELECT lastname, COUNT(firstname) AS n_emp '.
        'FROM T_Employee '.
        'GROUP BY lastname HAVING ((n_emp >= ?)) '.
        'ORDER BY n_emp DESC', [2], 'group by');

# -order_by with +/- prefixes on columns
$lst = HR::Employee->select(-order_by => [qw/+col1 -col2 +col3/]);
sqlLike('SELECT * FROM T_Employee ORDER BY col1 ASC, col2 DESC, col3 ASC', 
        [], '-order_by prefixes');



# paging
HR->table('Employee')->select(
  -page_size => 10,
  -page_index => 3,
 );
sqlLike('SELECT * FROM T_Employee LIMIT ? OFFSET ?',
        [10, 20],
        'page 3 from initial request');






# -limit 0
HR->table('Employee')->select(
  -columns => [qw/foo bar/],
  -limit   => 0,
 );
sqlLike('SELECT foo, bar FROM T_Employee LIMIT ? OFFSET ?',
        [0, 0],
        'limit 0');




# select with OR through an arrayref
my $result = HR::Employee->select(-where => [foo => 1, bar => 2]);
sqlLike('SELECT * FROM T_Employee WHERE foo = ? OR bar = ?',
        [qw/1 2/], "where arrayref, OR");

# fetch
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

#----------------------------------------------------------------------
# test path methods
#----------------------------------------------------------------------

# initialize object for tests below
$emp->{emp_id} = 999;

# plain method call
$lst = $emp->activities;
sqlLike('SELECT * FROM T_Activity WHERE ( emp_id = ? )',
        [999],
        'activities');

# with -columns arg
$lst = $emp->activities(-columns => [qw/d_begin d_end/]);
sqlLike('SELECT d_begin, d_end FROM T_Activity WHERE ( emp_id = ? )',
        [999],
        'activities column list');

# with -where arg
$lst = $emp->activities(-where => {d_begin => {">=" => '2000-01-01'}});
sqlLike('SELECT * FROM T_Activity WHERE (d_begin >= ? AND emp_id = ?)',
        ['2000-01-01', 999],
        'activities where criteria');

# with -order_by
$lst = $emp->activities(-columns  => "d_begin AS db, d_end AS de", 
                        -order_by => [qw/d_begin d_end/]);
sqlLike('SELECT d_begin AS db, d_end AS de FROM T_Activity WHERE (emp_id = ?) '.
        'ORDER BY d_begin, d_end',
        [999], 
        'activities order by');

# with -fetch
$act = $emp->activities(-fetch => 123);
sqlLike('SELECT * FROM T_Activity WHERE (act_id = ? AND emp_id = ? )', 
        [123, 999], 'activities(-fetch)');

# testing cached expanded values
$emp->{activities} = "foo";
is ($emp->activities, "foo", "cached expanded values");
delete $emp->{activities};


# failure with empty foreign key
my $fake_emp = bless {}, 'HR::Employee';
die_ok {$fake_emp->activities()};


# self-referential association
$emp = HR::Employee->bless_from_DB({emp_id => 999, spouse_id => 888});
my $emp_spouse = $emp->spouse;
sqlLike('SELECT * ' .
        'FROM T_Employee ' .
        "WHERE ( emp_id = ? )", [888], 'spouse self-ref assoc.');


# meta-information about paths
my $emp_meta = HR->table('Employee')->metadm;
my %paths = $emp_meta->path;
while (my ($path_name, $path)= each %paths) {
  my $opp     = $path->opposite or next; # some paths like 'spouse' have no opp
  my $opp_opp = $opp->opposite;
  isa_ok($opp, 'DBIx::DataModel::Meta::Path', "opposite is a Path");
  isnt($path, $opp,                           "opposite is different");
  is($path, $opp_opp,                         "opposite of opposite")
}


#----------------------------------------------------------------------
# test Statement class
#----------------------------------------------------------------------


# stepwise combination of where criteria
my $statement = HR::Employee->activities(-where => {foo => [3, 4]});
$act = $statement->bind($emp)
                 ->select(-where => {foo => [4, 5]});
sqlLike('SELECT * FROM T_Activity '
        .  'WHERE ( emp_id = ? AND ( (     foo = ? OR foo = ? ) '
        .                           'AND ( foo = ? OR foo = ? )))',
        [999, 3, 4, 4, 5], "combined where");

# other combination involving nested arrayrefs
$statement = HR->table('Employee')->activities(-where => [foo => "bar", bar => "foo"]);
$act = $statement->bind($emp)
                 ->select(-where => [foobar => 123, barfoo => 456]);

sqlLike('SELECT * FROM T_Activity '
        .  'WHERE ( (     (foo = ?  OR bar = ?) '
        .            'AND (foobar = ? OR barfoo = ?)'
        .          ') AND emp_id = ? )',
        [qw/bar foo 123 456 999/], "combined where, arrayrefs");



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


# -pre_exec / -post_exec callbacks
my %check_callbacks;
HR::Employee->select(-where => {foo=>'bar'},
      	   -pre_exec => sub {$check_callbacks{pre} = "was called"},
      	   -post_exec => sub {$check_callbacks{post} = "was called"},);
is_deeply(\%check_callbacks, {pre =>"was called", 
      			post => "was called" }, 'select, pre/post callbacks');

%check_callbacks = ();
HR::Employee->fetch(1234, {-pre_exec => sub {$check_callbacks{pre} = "was called"},
      		 -post_exec => sub {$check_callbacks{post} = "was called"}});
is_deeply(\%check_callbacks, {pre =>"was called", 
      			post => "was called" }, 'fetch, pre/post callbacks');


# nb_fetched_rows
HR->dbh->{mock_add_resultset} = [[qw/foo bar/], ([1, 2]) x 23];
$statement = HR->table('Employee')->select(-result_as  => 'statement');
$statement->all; # throw away the result -- this call is just to make sure the statement is finished
is $statement->nb_fetched_rows, 23, "nb_fetched_rows";


# page boundaries
HR->dbh->{mock_add_resultset} = [[qw/foo bar/], ([1, 2]) x 5];
$statement = HR->table('Employee')->select(
  -page_size  => 10,
  -page_index => 3,
  -result_as  => 'statement',
 );
$statement->all; # throw away the result -- this call is just to make sure the statement is finished
is_deeply [$statement->page_boundaries], [21, 25], "page boundaries";


# -union
my $stmt = HR->table('Employee')->select(
  -columns   => [qw/emp_id firstname lastname/],
  -where     => {d_birth => '01.01.1950'},
  -union     => [-where  => {d_spouse => '01.01.1950'}],
  -result_as => 'statement',
 );

my $rows = $stmt->all;
sqlLike(<<__EOSQL__, [qw/01.01.1950 01.01.1950/], "sql union");
  SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_birth = ? ) 
  UNION 
  SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_spouse = ? )
__EOSQL__


my $n = $stmt->row_count;
sqlLike(<<__EOSQL__, [qw/01.01.1950 01.01.1950/], "sql count from union");
  SELECT COUNT(*) FROM (
    SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_birth = ? )
    UNION 
    SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_spouse = ? )
  ) AS count_wrapper
__EOSQL__



# -union_all
HR->table('Employee')->select(
  -columns   => [qw/emp_id firstname lastname/],
  -where     => {d_birth => {'>=' => '01.01.1950'}},
  -union_all => [-where  => {d_spouse => {'>=' => '02.02.1950'}}],
 );
sqlLike(<<__EOSQL__, [qw/01.01.1950 02.02.1950/], "sql union all");
  SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_birth >= ? ) 
  UNION ALL
  SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_spouse >= ? )
__EOSQL__


# -intersect
HR->table('Employee')->select(
  -columns   => [qw/emp_id firstname lastname/],
  -where     => {d_birth => {'>=' => '01.01.1950'}},
  -intersect => [-where  => {d_spouse => {'>=' => '02.02.1950'}}],
 );
sqlLike(<<__EOSQL__, [qw/01.01.1950 02.02.1950/], "sql intersect");
  SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_birth >= ? ) 
  INTERSECT
  SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_spouse >= ? )
__EOSQL__


# -except
HR->table('Employee')->select(
  -columns   => [qw/emp_id firstname lastname/],
  -where     => {d_birth => {'>=' => '01.01.1950'}},
  -except    => [-where  => {d_spouse => {'>=' => '02.02.1950'}}],
 );
sqlLike(<<__EOSQL__, [qw/01.01.1950 02.02.1950/], "sql except");
  SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_birth >= ? ) 
  EXCEPT
  SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_spouse >= ? )
__EOSQL__


# -minus -- currently not supported by SQL::Abstract::Test in v2.0
# HR->table('Employee')->select(
#   -columns   => [qw/emp_id firstname lastname/],
#   -where     => {d_birth => {'>=' => '01.01.1950'}},
#   -minus     => [-where  => {d_spouse => {'>=' => '02.02.1950'}}],
#  );
# sqlLike(<<__EOSQL__, [qw/01.01.1950 02.02.1950/], "sql minus");
#   SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_birth >= ? )
#   MINUS
#   SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_spouse >= ? )
# __EOSQL__



#----------------------------------------------------------------------
# result kinds
#----------------------------------------------------------------------

# select -resultAs => 'flat_arrayref'
my @fake_rs = ([qw/col1 col2/], [qw/foo1 foo2/], [qw/bar1 bar2/]);
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = \@fake_rs;
my $pairs = HR::Employee->select(-columns  => [qw/col1 col2/],
                                 -result_as => 'flat_arrayref');
is_deeply($pairs, [qw/foo1 foo2 bar1 bar2/], "result_as => 'flat_arrayref'");

# reversed
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = [map {[reverse @$_]} @fake_rs];
$pairs = HR::Employee->select(-columns  => [qw/col2 col1/],
                              -result_as => 'flat_arrayref');
is_deeply($pairs, [qw/foo2 foo1 bar2 bar1/], "result_as => 'flat_arrayref'");


# select -resultAs => 'hashref'
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = [ [qw/emp_id foo/],
                               [qw/1 1/],
                               [qw/2 2/],
                               [qw/1 1bis/],
                              ];
my $hashref = HR::Employee->select(
  -result_as => 'hashref'
 );
is_deeply($hashref, {1 => {emp_id => 1, foo => '1bis'},
                     2 => {emp_id => 2, foo => 2}},
            "resultAs => 'hashref'");

# nested hashref on given columns
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = [ [qw/emp_id foo/],
                               [qw/1 1/], 
                               [qw/2 2/],
                               [qw/1 1bis/],
                              ];
$hashref = HR->join(qw/Employee activities/)->select(
  -result_as => [hashref => qw/emp_id foo/],
 );
is_deeply($hashref, {1 => {1      => {emp_id => 1, foo => 1},
                           '1bis' => {emp_id => 1, foo => '1bis'}},
                     2 => {2      => {emp_id => 2, foo => 2}}},
            'result_as => [hashref => @cols]');


# subquery
my $subquery = HR::Employee->select(
  -columns  => 'emp_id',
  -where    => {d_birth => {-between => [1950, 1980]}},
  -result_as => 'subquery',
 );
$act = HR::Activity->select(-where => {emp_id => {-not_in => $subquery}});
sqlLike('SELECT * FROM T_Activity WHERE emp_id NOT IN '
          . '(SELECT emp_id FROM T_Employee WHERE d_birth BETWEEN ? AND ?)',
        [1950, 1980],
        'subquery');



#----------------------------------------------------------------------
# test joins
#----------------------------------------------------------------------

# regular join
my $join = HR->join(qw/Employee activities department/);
$join->select(-columns => "lastname, dpt_name",
              -where   => {gender => 'F'});
sqlLike('SELECT lastname, dpt_name ' .
        'FROM T_Employee LEFT OUTER JOIN T_Activity ' .
        'ON T_Employee.emp_id=T_Activity.emp_id ' .
        'LEFT OUTER JOIN T_Department ' .
        'ON T_Activity.dpt_id=T_Department.dpt_id ' .
        'WHERE (gender = ?)',
           ['F'], 'join');


# explicit join kinds
$join = HR->join(qw/Employee <=> activities => department/);
$join->select(-columns => "lastname, dpt_name",
              -where   => {gender => 'F'});

sqlLike('SELECT lastname, dpt_name ' .
        'FROM T_Employee INNER JOIN T_Activity ' .
        'ON T_Employee.emp_id=T_Activity.emp_id ' .
        'LEFT OUTER JOIN T_Department ' .
        'ON T_Activity.dpt_id=T_Department.dpt_id ' .
        'WHERE (gender = ?)', ['F'], 'join with explicit join kinds');


# indirect association
$join = HR->join(qw/Activity employee department/);
$join->select(-columns => "lastname, dpt_name",
              -where   => {gender => 'F'});

sqlLike('SELECT lastname, dpt_name ' .
        'FROM T_Activity INNER JOIN T_Employee ' .
        'ON T_Activity.emp_id=T_Employee.emp_id ' .
        'INNER JOIN T_Department ' .
        'ON T_Activity.dpt_id=T_Department.dpt_id ' .
        'WHERE (gender = ?)', ['F'], 'join with indirect association');



# option "join_with_USING"
$join = HR->join(qw/Employee activities department/);
$join->select(-columns => "lastname, dpt_name",
              -where   => {gender => 'F'},
              -join_with_USING => 1);
sqlLike('SELECT lastname, dpt_name ' .
        'FROM T_Employee LEFT OUTER JOIN T_Activity ' .
        'USING (emp_id) ' .
        'LEFT OUTER JOIN T_Department ' .
        'USING (dpt_id) ' .
        'WHERE (gender = ?)',
           ['F'], 'join_with_USING');


# check that  "join_with_USING" was really temporary
$join = HR->join(qw/Employee activities department/);
$join->select(-columns => "lastname, dpt_name",
              -where   => {gender => 'F'},
              );
sqlLike('SELECT lastname, dpt_name ' .
        'FROM T_Employee LEFT OUTER JOIN T_Activity ' .
        'ON T_Employee.emp_id=T_Activity.emp_id ' .
        'LEFT OUTER JOIN T_Department ' .
        'ON T_Activity.dpt_id=T_Department.dpt_id ' .
        'WHERE (gender = ?)',
           ['F'], 'after join_with_USING');


# "join_with_USING" set at the schema level
{
  local HR->singleton->{join_with_USING} = 1;
  $join = HR->join(qw/Employee activities department/);
  $join->select(-columns => "lastname, dpt_name",
                -where   => {gender => 'F'});
  sqlLike('SELECT lastname, dpt_name ' .
          'FROM T_Employee LEFT OUTER JOIN T_Activity ' .
          'USING (emp_id) ' .
          'LEFT OUTER JOIN T_Department ' .
          'USING (dpt_id) ' .
          'WHERE (gender = ?)',
             ['F'], 'join_with_USING at schema level');


  HR->join(qw/Employee activities/)->select(
    -columns         => "lastname, dpt_name",
    -where           => {gender => 'F'},
    -join_with_USING => undef,
   );
  sqlLike('SELECT lastname, dpt_name ' .
          'FROM T_Employee LEFT OUTER JOIN T_Activity ' .
          'ON T_employee.emp_id = T_Activity.emp_id ' .
          'WHERE (gender = ?)',
             ['F'], 'local cancellation of join_with_USING');
}


# wrong paths
die_ok {$emp->join(qw/activities foo/)};
die_ok {$emp->join(qw/foo bar/)};

# wrong join should produce a meaningful message
{ eval { HR->join(qw/foo activities/); };
  my $err = $@;
  like $err, qr/no table/, 'error message for wrong table in join' ;
}


# join from an instance
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = [ [qw/act_id  dpt_id/],
                               [qw/111     222   /],  ];
my $act_dpt = $emp->join(qw/activities department/)
                  ->select(-where => {gender => 'F'});
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

# table aliases in joins
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

# reversed
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



# multiple instances of the same table
my @to_join = qw/Employee <=> activities <=> department
                          <=> activities|other_act <=> employee|colleague/;
my @cols = qw/Employee.emp_id colleague.emp_id|colleague_id/;
$dbh->{mock_add_resultset} = [ [qw/emp_id  colleague_id/],
                               [qw/1 2/],
                               [qw/1 3/],
                               [qw/1 4/],
                               [qw/2 1/],
                              ];
my $first_colleague = HR->join(@to_join)->select(
  -columns   => \@cols,
  -result_as => 'firstrow',
 );
sqlLike(<<__EOSQL__, [], 'multiple instances of same table');
SELECT Employee.emp_id, colleague.emp_id AS colleague_id
      FROM T_Employee 
INNER JOIN T_Activity ON ( T_Employee.emp_id = T_Activity.emp_id )
INNER JOIN T_Department ON ( T_Activity.dpt_id = T_Department.dpt_id )
INNER JOIN T_Activity AS other_act ON ( T_Department.dpt_id = other_act.dpt_id )
INNER JOIN T_Employee AS colleague ON ( other_act.emp_id = colleague.emp_id )
__EOSQL__

is $first_colleague->can('activities'), HR::Employee->can('activities'),
  "proper inheritance of 'activities' method";
is $first_colleague->can('department'), HR::Activity->can('department'),
  "proper inheritance of 'department' method";


# where_on
HR->join(qw/Employee activities => department/)->select(
  -where => {firstname => 'Hector',
             dpt_name  => 'Music'},
  -where_on => {
     T_Activity   => {d_end => {"<" => '01.01.2001'}},
     T_Department => {dpt_head => 999},
   },
 );
my @expected_sql_bind = (<<__EOSQL__, [qw/01.01.2001 999 Music Hector/]);
     SELECT * FROM T_Employee 
       LEFT OUTER JOIN T_Activity
         ON T_Employee.emp_id = T_Activity.emp_id AND d_end < ?
       LEFT OUTER JOIN T_Department 
         ON T_Activity.dpt_id = T_Department.dpt_id AND dpt_head = ?
       WHERE dpt_name = ? AND firstname = ?
__EOSQL__
sqlLike(@expected_sql_bind, 'where_on');

# same test again, to check for possible side-effects in metadata
HR->join(qw/Employee activities => department/)->select(
  -where => {firstname => 'Hector',
             dpt_name  => 'Music'},
  -where_on => {
     T_Activity   => {d_end => {"<" => '01.01.2001'}},
     T_Department => {dpt_head => 999},
   },
 );
sqlLike(@expected_sql_bind, 'where_on again');

# proper error message if inappropriate usage
{ eval { HR->table('Employee')->select(-where_on => {Foo => 'bar'}); };
  my $err = $@;
  like $err, qr/where_on/, 'error message for wrong -where_on' ;
}



#----------------------------------------------------------------------
# test insert() method
#----------------------------------------------------------------------

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


# cascaded inserts
my $tree = {firstname  => "Johann Sebastian",  
            lastname   => "Bach",
            activities => [{d_begin  => '01.01.1707',
                            d_end    => '01.07.1720',
                            dpt_code => 'Maria-Barbara'},
                           {d_begin  => '01.12.1721',
                            d_end    => '18.07.1750',
                            dpt_code => 'Anna-Magdalena'}]};
my $emp_id = HR::Employee->insert(clone($tree));
my $sql_insert_activity = 'INSERT INTO T_Activity (d_begin, d_end, '
                        . 'dpt_code, emp_id) VALUES (?, ?, ?, ?)';
sqlLike('INSERT INTO T_Employee (firstname, lastname) VALUES (?, ?)',
        ["Johann Sebastian", "Bach"],
        $sql_insert_activity, 
        ['1707-01-01', '1720-07-01', 'Maria-Barbara', $emp_id],
        $sql_insert_activity, 
        ['1721-12-01', '1750-07-18', 'Anna-Magdalena', $emp_id],
        "cascaded insert");

# option -returning => {}
$dbh->{mock_start_insert_id} = 10;
$result   = HR::Employee->insert(clone($tree), -returning => {});
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



#----------------------------------------------------------------------
# test update() method
#----------------------------------------------------------------------

# syntax $class->update($pk, {...})
HR::Employee->update(999, {firstname => 'toto', 
                           d_modif => '02.09.2005',
                           d_birth => '01.01.1950',
                           last_login => '01.09.2005'});
sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ? '.
        'WHERE (emp_id = ?)', ['1950-01-01', 'toto', 999], 'update');


  # -set / -where / -ident
  HR->table('Employee')->update(
    -set   => {foo => 123},
    -where => {baz => {">" => {-ident => 'buz'}}},
   );
  sqlLike("UPDATE T_Employee SET foo = ? WHERE baz > buz",
          [123],
          "update(-set => .., -where => { ... -ident})");



# syntax $class->update($obj)
HR::Employee->update(     {firstname => 'toto', 
      		 d_modif => '02.09.2005',
      		 d_birth => '01.01.1950',
      		 last_login => '01.09.2005',
      		 emp_id => 999});
sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ? '.
        'WHERE (emp_id = ?)', ['1950-01-01', 'toto', 999], 'update2');


# syntax $instance->update()
$emp = HR::Employee->bless_from_DB({emp_id    => 999,
                                    firstname => 'Joseph',
                                    lastname  => 'BODIN DE BOISMORTIER',
                                    d_birth   => '1775-12-16'});
$emp->{firstname}  = 'toto';
$emp->{d_modif}    = '02.09.2005';
$emp->{d_birth}    = '01.01.1950';
$emp->{last_login} = '01.09.2005';
my %emp2 = %$emp;
$emp->update;
sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ?, lastname = ? '.
        'WHERE (emp_id = ?)',
        ['1950-01-01', 'toto', 'BODIN DE BOISMORTIER', 999], 'update3');

# direct call on a object instance, with args
$emp->update({bar => 987});
sqlLike("UPDATE T_Employee SET bar = ? WHERE emp_id = ?",
        [987, 999],
        "obj update with args");

# update using verbatim SQL
my $dt     = "01.02.1234 12:34";
HR->table('Employee')->update(
  $emp_id,
  {DT_field => \ ["TO_DATE(?, 'DD.MM.YYYY HH24:MI')", $dt]},
);
sqlLike("UPDATE T_Employee SET DT_field = TO_DATE(?, 'DD.MM.YYYY HH24:MI') "
       . "WHERE ( emp_id = ? )",
        [$dt, $emp_id],
        "update from function");

# in presence of subreferences, warn and then remove them
{ my $warn_msg = '';
  local $SIG{__WARN__} = sub {$warn_msg .= $_[0]};
  HR->table('Employee')->update(
    $emp_id, {foo => 123, skip1 => {bar => 456}, skip2 => bless({}, "Foo")},
   );
  
  sqlLike("UPDATE T_Employee SET foo = ? WHERE ( emp_id = ? )",
          [123, $emp_id],
          "skip sub-references");
  like $warn_msg, qr/nested references/, 'warn for nested references';
}

# update an unblessed record
my $record = {emp_id => $emp_id, foo => 'bar'};
HR->table('Employee')->update($record);
sqlLike("UPDATE T_Employee SET foo = ? WHERE emp_id = ?",
        ['bar', $emp_id],
        "class update unblessed");

# update a blessed record, 
$record = bless {emp_id => $emp_id, foo => 'bar'}, 'HR::Employee';
HR->table('Employee')->update($record);
sqlLike("UPDATE T_Employee SET foo = ? WHERE emp_id = ?",
        ['bar', $emp_id],
        "class update blessed");


# auto_update column handler (here added artificially through meta surgery)
HR->metadm->{auto_update_columns}{last_modif} =  sub{"someUser, someTime"};


HR::Employee->update(\%emp2);
sqlLike('UPDATE T_Employee SET d_birth = ?, firstname = ?, ' .
          'last_modif = ?, lastname = ? WHERE (emp_id = ?)', 
        ['1950-01-01', 'toto', "someUser, someTime", 
         'BODIN DE BOISMORTIER', 999], 'autoUpdate');

# idem with an auto_insert column handler
HR->metadm->{auto_insert_columns}{created_by} = sub{"firstUser, firstTime"};

HR::Employee->insert({firstname => "Felix",
                  lastname  => "Mendelssohn"});

sqlLike('INSERT INTO T_Employee (created_by, firstname, last_modif, lastname) ' .
          'VALUES (?, ?, ?, ?)',
        ['firstUser, firstTime', 'Felix', 'someUser, someTime', 'Mendelssohn'],
        'autoUpdate / insert');


#----------------------------------------------------------------------
# test delete() method
#----------------------------------------------------------------------

# class method with -where
HR::Employee->delete(-where => {foo => 'bar'});
sqlLike('DELETE FROM T_Employee WHERE (foo = ?)', ['bar'], 'delete -where');

# class method with primary key
$emp_id = 123;
HR::Employee->delete($emp_id);
sqlLike("DELETE FROM T_Employee WHERE emp_id = ? ", 
        [$emp_id],
        "delete");

# idem, but through connected source
HR->table('Employee')->delete($emp_id);
sqlLike("DELETE FROM T_Employee WHERE emp_id = ? ", 
        [$emp_id],
        "delete");


# instance method
$emp = HR::Employee->bless_from_DB({emp_id => 999});
$emp->delete;
sqlLike('DELETE FROM T_Employee WHERE (emp_id = ?)', [999], 'delete instance');


#----------------------------------------------------------------------
# test transactions
#----------------------------------------------------------------------

# coderefs for tests
my $ok_trans       = sub { return "scalar transaction OK"     };
my $ok_trans_array = sub { return qw/array transaction OK/    };
my $fail_trans     = sub { die "failed transaction"           };
my $nested_1       = sub { HR->do_transaction($ok_trans) };
my $nested_many    = sub {
  my $r1 = HR->do_transaction($nested_1);
  my @r2 = HR->do_transaction($ok_trans_array);
  return ($r1, @r2);
};

# return value according to context
is (HR->do_transaction($ok_trans), 
    "scalar transaction OK",
    "scalar transaction");
sqlLike('BEGIN WORK', [], 
        'COMMIT',     [], "scalar transaction commit");

is_deeply ([HR->do_transaction($ok_trans_array)],
           [qw/array transaction OK/],
           "array transaction");
sqlLike('BEGIN WORK', [], 
        'COMMIT',     [], "array transaction commit");

# rollback
die_ok {HR->do_transaction($fail_trans)};
sqlLike('BEGIN WORK', [], 
        'ROLLBACK',   [], "fail transaction rollback");

# nested
$dbh->do('FAKE SQL, HISTORY MARKER');
is_deeply ([HR->do_transaction($nested_many)],
           ["scalar transaction OK", qw/array transaction OK/],
           "nested transaction");
sqlLike('FAKE SQL, HISTORY MARKER', [],
        'BEGIN WORK', [], 
        'COMMIT',     [], "nested transaction commit");


# exceptions
eval {HR->do_transaction($fail_trans)};
my $err = $@;
like ($err->initial_error, qr/^failed transaction/, "initial_error");
is_deeply([$err->rollback_errors], [], "rollback_errors");


# material for testing nested transactions on two different databases
$dbh->{private_id} = "dbh1";
my $other_dbh = DBI->connect('DBI:Mock:', '', '', 
                             {private_id => "dbh2", RaiseError => 1});


# material for testing the ->do_after_commit() method
$emp_id = 66;
my @publish_trans;
my $tell_dbh_id = sub {my $db_id = HR->dbh->{private_id};
                       HR::Employee->update({emp_id => $emp_id++, name => $db_id});
                       HR->do_after_commit(sub {push @publish_trans,
                                                "did work on $db_id"});
                       return "transaction on $db_id" };

# nested transactions on two different databases
my $nested_change_dbh = sub {
  my $r1 = HR->do_transaction($tell_dbh_id);
  my $r2 = HR->do_transaction($tell_dbh_id, $other_dbh);
  my $r3 = HR->do_transaction($tell_dbh_id);
  return ($r1, $r2, $r3);
};
$dbh      ->do('FAKE SQL, BEFORE TRANSACTION');
$other_dbh->do('FAKE SQL, BEFORE TRANSACTION');
is_deeply ([HR->do_transaction($nested_change_dbh)],
           ["transaction on dbh1", 
            "transaction on dbh2", 
            "transaction on dbh1"],
            "nested transaction, change dbh");

# ->do_after_commit() method
is_deeply \@publish_trans, ["did work on dbh1",
                            "did work on dbh2",
                            "did work on dbh1"], "after_commit";

# check SQL generated by the nested transaction
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


# RT#99205 : side-effect when trying a transaction without a DB connection
my $do_work = sub {Tst->table('Foo')->select};

# Trying to do a transaction without a DB connection ... normally
# this raises an exception, but if captured in a eval, we don't see the
# exception, and it has the naughty side-effect of silently setting
# Tst->singleton->{dbh} = {}
eval {HR->do_transaction($do_work)};

# now $schema->{dbh} is true but $schema->{dbh}[0]{AutoCommit} is false,
# so it looks like we are running a transaction
# ==> before bug fix, croak "cannot change dbh(..) while in a transaction";
HR->dbh($dbh);

# after bug fix, this works
ok scalar(HR->dbh), "schema has a dbh";




#----------------------------------------------------------------------
# END OF TESTS
#----------------------------------------------------------------------

done_testing;

__END__


TODO:
  hasInvalidFields
  expand
  autoExpand
  select(-dbi_prepare_method => ..)

