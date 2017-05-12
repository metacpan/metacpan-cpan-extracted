use Test::More tests => 57;
use strict;
use warnings;

my $sql_i = 0;

BEGIN {
        use_ok('DBI');
        use_ok('DBomb');
        use_ok('DBomb::Query');
        use_ok('DBomb::Query::Insert');
        use_ok('DBomb::Test::Util',qw(:all));
};

## Connect
my ($dbh,$q);
ok($dbh = DBI->connect(undef,undef,undef,+{RaiseError=>1, PrintError=>1}), 'connect to database');

##=============##
##   SELECTS   ##
##=============##

## First, just grab data with no particular goal -- just see if anything breaks
my @queries = (
    ## simple select
    new DBomb::Query($dbh)->select(qw(title))->from('employee'),
    new DBomb::Query($dbh)->select(qw(cli_id name))->from('client'),
    new DBomb::Query($dbh)->select(qw(name max_hours))->from('project'),
    new DBomb::Query($dbh)->select(qw(emp_id prj_id))->from('emp_prj'),
    new DBomb::Query($dbh)->select(qw(tsk_name))->from('task'),
    new DBomb::Query($dbh)->select(qw(begin_time end_time))->from('hours'),

    ## simple clauses
    new DBomb::Query($dbh)->select(qw(title))->from('employee')->order_by('title')->limit(2),
    new DBomb::Query($dbh)->select(qw(cli_id name))->from('client')->order_by('name')->asc(),
    new DBomb::Query($dbh)->select(qw(name max_hours))->from('project')->order_by('name')->desc()->limit(3),
    new DBomb::Query($dbh)->select(qw(DISTINCT(begin_time)))->from('hours'),

    ## where clause syntax silliness
    new DBomb::Query($dbh)->select(qw(title))->from('employee')->where("emp_id < 4"),
    new DBomb::Query($dbh)->select(qw(title))->from('employee')->where(+{emp_id => [qw(< 4)]}),
    new DBomb::Query($dbh)->select(qw(title))->from('employee')->where(+{emp_id => [qw(< ?)]}, 4),
    new DBomb::Query($dbh)->select(qw(title))->from('employee')->where(+{title => '?'}, 'CEO'),
    new DBomb::Query($dbh)->select(qw(cli_id name))->from('client')->where([{cli_id => 2}, 'OR', {cli_id => 3}]),
    new DBomb::Query($dbh)->select(qw(name max_hours))->from('project')->where([+{max_hours => [qw(> 40)]}]),

    ## 2-table joins
    new DBomb::Query($dbh)->select(qw(client.name project.name))->from('client')
                        ->join('project')->on(+{'client.cli_id' => 'project.cli_id'})->order_by('client.cli_id'),
    new DBomb::Query($dbh)->select(qw(e1.name e2.name))->from('employee e1')
                        ->join('employee e2')->on(+{'e1.mgr' => 'e2.emp_id'}),
    new DBomb::Query($dbh)->select(qw(e1.name e2.name))->from('employee e1')
                        ->left_join('employee e2')->on(+{'e1.mgr' => 'e2.emp_id'}),
    new DBomb::Query($dbh)->select(qw(e1.name e2.name))->from('employee e1')
                        ->right_join('employee e2')->on(+{'e1.mgr' => 'e2.emp_id'}),

    ## 4-table join with ON
    new DBomb::Query($dbh)->select(qw(c.name  p.name  e.name))->from('emp_prj ep')
                        ->join('employee e')->on(+{'ep.emp_id' => 'e.emp_id'})
                        ->join('project p')->on(+{'p.prj_id' => 'ep.prj_id'})
                        ->join('client c')->on(+{'c.cli_id' => 'p.cli_id'}),

    ## 4-table join with USING
    new DBomb::Query($dbh)->select(qw(c.name  p.name  e.name))->from('emp_prj ep')
                        ->join('employee e')->on({'ep.emp_id' => 'e.emp_id'})
                        ->join('project p')->on({'p.prj_id' => 'ep.prj_id'})
                        ->join('client c')->using('cli_id'),

    ## Total hours per project having positive hours logged.
    new DBomb::Query($dbh)->select(qw(p.name))
                        ->select("SUM(HOUR(h.end_time - h.begin_time)) as hrs")
                        ->from('project p')
                        ->join('hours h')->using('prj_id')
                        ->group_by('p.name')
                        ->having({ hrs => [qw(> ?)]}, 0)
                        ->order_by('p.name'),
);

##
## Execute each query, checking only for success.
##
for my $q (@queries) {

    my $msg = "SQL[@{[$sql_i++]}]: " . scalar $q->sql;
    eval {
        $q->prepare($dbh);
        $q->execute();
        while(my $row = $q->fetchrow_arrayref){
        }
    };
    print STDERR "$msg\n" if $@;
    ok(!$@, $msg);
}

##======================##
##   SELECT AND VERIFY  ##
##======================##

## Execute queries, checking for expected return values, row counts, etc.
##

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(name))->from('employee')->order_by('name'),
                ["SELECT name FROM employee ORDER BY name ASC"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(cli_id name))->from('client'),
                ["SELECT cli_id,name FROM client"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(emp_id prj_id))->from('emp_prj'),
                ["SELECT emp_id,prj_id FROM emp_prj"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(tsk_name))->from('task'),
                ["SELECT tsk_name FROM task"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(begin_time end_time))->from('hours'),
                ["SELECT begin_time,end_time FROM hours"]));

## simple clauses
ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(title))->from('employee')->order_by('title')->limit(2),
                ["SELECT title FROM employee ORDER BY title ASC  LIMIT  0, 2"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(cli_id name))->from('client')->order_by('name')->asc(),
                ["SELECT cli_id,name FROM client ORDER BY name ASC"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(name max_hours))->from('project')->order_by('name')->desc()->limit(3),
                ["SELECT name,max_hours FROM project ORDER BY name DESC  LIMIT  0, 3"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(DISTINCT(begin_time)))->from('hours'),
                ["SELECT DISTINCT(begin_time) FROM hours"]));

## where clause syntax silliness
ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(title))->from('employee')->where('emp_id < 4'),
                ["SELECT title FROM employee WHERE (emp_id < 4)"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(title))->from('employee')->where(+{emp_id => [qw(< 4)]}),
                ["SELECT title FROM employee WHERE (emp_id < 4)"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(title))->from('employee')->where(+{emp_id => [qw(< ?)]}, 4),
                ["SELECT title FROM employee WHERE (emp_id < ?)", 4]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(title))->from('employee')->where(+{title => '?'}, 'CEO'),
                ["SELECT title FROM employee WHERE (title = ?)", "CEO"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(cli_id name))->from('client')->where([{cli_id => 2}, 'OR', {cli_id => 3}]),
                ["SELECT cli_id,name FROM client WHERE (cli_id = 2 OR cli_id = 3)"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(name max_hours))->from('project')->where([+{max_hours => [qw(> 40)]}]),
                ["SELECT name,max_hours FROM project WHERE (max_hours > 40)"]));

## 2-table joins
ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(client.name project.name))->from('client')
                                    ->join('project')->on(+{'client.cli_id' => 'project.cli_id'})->order_by('client.cli_id'),
                ["SELECT client.name,project.name FROM client  JOIN project ON (client.cli_id = project.cli_id)  ORDER BY client.cli_id ASC"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(e1.name e2.name))->from('employee e1')
                                    ->join('employee e2')->on(+{'e1.mgr' => 'e2.emp_id'}),
                ["SELECT e1.name,e2.name FROM employee e1  JOIN employee e2 ON (e1.mgr = e2.emp_id)"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(e1.name e2.name))->from('employee e1') ->left_join('employee e2')->on(+{'e1.mgr' => 'e2.emp_id'}),
                ["SELECT e1.name,e2.name FROM employee e1 LEFT JOIN employee e2 ON (e1.mgr = e2.emp_id)"]));

ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(e1.name e2.name))->from('employee e1') ->right_join('employee e2')->on(+{'e1.mgr' => 'e2.emp_id'}),
                ["SELECT e1.name,e2.name FROM employee e1 RIGHT JOIN employee e2 ON (e1.mgr = e2.emp_id)"]));


## 4-table join with ON
ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(c.name  p.name  e.name))->from('emp_prj ep')
                                    ->join('employee e')->on(+{'ep.emp_id' => 'e.emp_id'})
                                    ->join('project p')->on(+{'p.prj_id' => 'ep.prj_id'})
                                    ->join('client c')->on(+{'c.cli_id' => 'p.cli_id'}),
                ["SELECT c.name,p.name,e.name FROM emp_prj ep
                  JOIN employee e ON (ep.emp_id = e.emp_id)
                  JOIN project p ON (p.prj_id = ep.prj_id)
                  JOIN client c ON (c.cli_id = p.cli_id)"]));

## 4-table join with USING
ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(c.name  p.name  e.name))->from('emp_prj ep')
                                    ->join('employee e')->on({'ep.emp_id' => 'e.emp_id'})
                                    ->join('project p')->on({'p.prj_id' => 'ep.prj_id'})
                                    ->join('client c')->using('cli_id'),
                ["SELECT c.name,p.name,e.name
                  FROM emp_prj ep  JOIN employee e ON (ep.emp_id = e.emp_id)
                  JOIN project p ON (p.prj_id = ep.prj_id)
                  JOIN client c USING ( cli_id)"]));

## Total hours per project having positive hours logged.
ok(same_results($dbh, new DBomb::Query($dbh)->select(qw(p.name))
                                    ->select('SUM(HOUR(h.end_time - h.begin_time)) as hrs') ->from('project p')
                                    ->join('hours h')->using('prj_id')
                                    ->group_by('p.name')->having(+{ hrs => [qw(> ?)]}, 0)
                                    ->order_by('p.name'),
                ["SELECT p.name,SUM(HOUR(h.end_time - h.begin_time)) as hrs
                  FROM project p  JOIN hours h USING ( prj_id)
                  GROUP BY p.name HAVING (hrs > 0)
                  ORDER BY p.name ASC"]));

##=============##
##   INSERTS   ##
##=============##

## insert into client(name)
my $cli_name = 'Microsoft';

ok($q = new DBomb::Query::Insert('name')->into('client')->values($cli_name), 'create insert into client');
ok($q->insert($dbh),'insert');
$q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM client WHERE name = '$cli_name'");
ok(@$q && $q->[0] == 1, 'verify that row was inserted');
$dbh->do("DELETE FROM client WHERE name = '$cli_name'");

## insert into employee(name,title)
my $ename = 'Joe';
my $etitle = 'Joker';
ok($q = new DBomb::Query::Insert()->columns([qw(name title)])
                                ->into('employee')
                                ->values($ename,$etitle), 'create insert into employee');
ok($q->insert($dbh),'insert');
$q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM employee WHERE name = '$ename' AND title = '$etitle'");
ok(@$q && $q->[0] == 1, 'verify that row was inserted');
$dbh->do("DELETE FROM employee WHERE name = '$ename' AND title = '$etitle'");


1;
# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
