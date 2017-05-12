package main;
use Test::More tests => 37;
use strict;
use warnings;
use Cwd;

my $sql_i = 0;

BEGIN {
        use_ok('DBI');
        use_ok('DBomb', qw(PlaceHolder));
        use_ok('DBomb::Query');
        use_ok('DBomb::Query::Insert');
        use_ok('DBomb::Test::Util',qw(:all));
        use_ok('DBomb::Test::Objects');
        use_ok('DBomb::Query::Expr',qw(expr));
};

## Connect
my ($dbh,$q);
ok($dbh = $DBomb::Test::Util::dbh
        = DBI->connect(undef,undef,undef,+{RaiseError=>1, PrintError=>1}), 'connect to database');
DBomb->dbh($dbh);

################################################################################3

##
## --  Client  --
##
package Client;
use strict;
use warnings;
use base qw(DBomb::Base);

__PACKAGE__->def_data_source(undef,'client');
__PACKAGE__->def_accessor('cli_id', +{ is_generated => 1 } );
__PACKAGE__->def_primary_key('cli_id');
__PACKAGE__->def_accessor('name');
1;
## end package


##
## --  Emp_prj  --
##
package Emp_prj;
use strict;
use warnings;
use base qw(DBomb::Base);

__PACKAGE__->def_data_source(undef,'emp_prj');
__PACKAGE__->def_accessor('emp_id');
__PACKAGE__->def_primary_key('emp_id');
__PACKAGE__->def_accessor('prj_id');
__PACKAGE__->def_accessor('max_hours');
1;
## end package


##
## --  Employee  --
##
package Employee;
use strict;
use warnings;
use base qw(DBomb::Base);

__PACKAGE__->def_data_source(undef,'employee');
__PACKAGE__->def_accessor('emp_id', +{ auto_increment => 1} );
__PACKAGE__->def_primary_key('emp_id');
__PACKAGE__->def_accessor('name');
__PACKAGE__->def_accessor('title');
__PACKAGE__->def_accessor('mgr');
1;
## end package


##
## --  Hours  --
##
package Hours;
use strict;
use warnings;
use base qw(DBomb::Base);

__PACKAGE__->def_data_source(undef,'hours');
__PACKAGE__->def_accessor('emp_id');
__PACKAGE__->def_primary_key('emp_id');
__PACKAGE__->def_accessor('prj_id');
__PACKAGE__->def_accessor('tsk_name');
__PACKAGE__->def_accessor('begin_time');
__PACKAGE__->def_accessor('end_time');
1;
## end package


##
## --  Project  --
##
package Project;
use strict;
use warnings;
use base qw(DBomb::Base);

__PACKAGE__->def_data_source(undef,'project');
__PACKAGE__->def_accessor('prj_id');
__PACKAGE__->def_primary_key('prj_id');
__PACKAGE__->def_accessor('name');
__PACKAGE__->def_accessor('cli_id');
__PACKAGE__->def_accessor('max_hours');
1;
## end package


##
## --  Task  --
##
package Task;
use strict;
use warnings;
use base qw(DBomb::Base);

__PACKAGE__->def_data_source(undef,'task');
__PACKAGE__->def_accessor('tsk_name');
__PACKAGE__->def_primary_key('tsk_name');
1;
## end package


##
## --  Task_cost  --
##
package Task_cost;
use strict;
use warnings;
use base qw(DBomb::Base);

__PACKAGE__->def_data_source(undef,'task_cost');
__PACKAGE__->def_accessor('emp_id');
__PACKAGE__->def_primary_key('emp_id');
__PACKAGE__->def_accessor('tsk_name');
__PACKAGE__->def_accessor('rate');
1;
## end package


##
## -- main --
##
package main;
use strict;
use warnings;
use Carp qw(croak);

$SIG{__DIE__} = sub { croak @_ };

eval { DBomb->resolve };
if ($@){ diag($@); fail('DBomb->resolve') }
else   { pass('DBomb->resolve') }

##=============##
##   INSERTS   ##
##=============##

## insert into client(name)
    my $cli_name = 'Microsoft';
    my $client = new Client();
    $client->name($cli_name);
    ok($client->insert($dbh),'insert into client');

    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM client WHERE name = '$cli_name'");
    ok(@$q && $q->[0] == 1, 'verify that row was inserted');

    ## Make a copy of it

    my $new_cli = $client->copy_shallow($dbh);
    ok(defined($new_cli), 'copied a client');
    ok($new_cli->cli_id ne $client->cli_id, 'verify client ids are different');
    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM client WHERE cli_id = ?",+{},$new_cli->cli_id);
    ok(@$q && $q->[0] == 1, 'verify that row was inserted');
    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM client WHERE name = '$cli_name'");
    ok(@$q && $q->[0] == 2, 'verify that both copies coexist');

    $dbh->do("DELETE FROM client WHERE name = '$cli_name'");

## insert into employee(name,title)
    my $ename = 'Joe';
    my $etitle = 'Joker';
    my $emp = new Employee();
    $emp->name($ename);
    $emp->title($etitle);
    ok($emp->insert($dbh),'insert into employee');

    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM employee WHERE name = '$ename' AND title = '$etitle'");
    ok(@$q && $q->[0] == 1, 'verify that row was inserted');
    $dbh->do("DELETE FROM employee WHERE name = '$ename' AND title = '$etitle'");


## insert, then update -- this tests the auto_increment deal
    $ename = 'Joe';
    $etitle = 'Joker';
    $emp = new Employee();

    $emp->name($ename);
    $emp->title($etitle);
    ok($emp->insert($dbh),'insert into employee');

    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM employee WHERE name = '$ename' AND title = '$etitle'");
    ok(@$q && $q->[0] == 1, 'verify that row was inserted');

    my $emp_id = $emp->emp_id;
    $q = $dbh->selectcol_arrayref("SELECT MAX(emp_id) FROM employee");
    ok( @$q && $q->[0] == $emp_id, 'verify new emp_id');

    $emp->mgr; ## should trigger a SELECT
    pass('triggered a select based on new emp_id');
    $dbh->do("DELETE FROM employee WHERE name = '$ename' AND title = '$etitle'");

##
## Same as above, but using class methods
##

## insert into client(name)
    $cli_name = 'Microsoft';
    ok(Client->insert($dbh,[qw(name)])->values($cli_name)->insert, 'insert into client');

    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM client WHERE name = '$cli_name'");
    ok(@$q && $q->[0] == 1, 'verify that row was inserted');
    $dbh->do("DELETE FROM client WHERE name = '$cli_name'");

## insert into employee(name,title)
    $ename = 'Joe';
    $etitle = 'Joker';
    ok(Employee->insert(qw(name title mgr))->values($ename,$etitle,undef)->insert($dbh),'insert into employee');

    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM employee WHERE name = '$ename' AND title = '$etitle'");
    ok(@$q && $q->[0] == 1, 'verify that row was inserted');
    $dbh->do("DELETE FROM employee WHERE name = '$ename' AND title = '$etitle'");

## insert using hash

    ## insert into client(name)
    $cli_name = 'Microsoft';
    ok(Client->insert($dbh, +{ name => $cli_name})->insert, 'insert into client');

    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM client WHERE name = '$cli_name'");
    ok(@$q && $q->[0] == 1, 'verify that row was inserted');
    $dbh->do("DELETE FROM client WHERE name = '$cli_name'");

    ## insert into employee(name,title)
    $ename = 'Joe';
    $etitle = 'Joker';
    ok(Employee->insert($dbh, +{ name => $ename, 'employee.title' => $etitle, bogus => 'ignore me' })->prepare->execute,'insert into employee');

    $q = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM employee WHERE name = '$ename' AND title = '$etitle'");
    ok(@$q && $q->[0] == 1, 'verify that row was inserted');
    $dbh->do("DELETE FROM employee WHERE name = '$ename' AND title = '$etitle'");

# insert using scalar
    ok(truncate_table('task_cost'), 'clear table task_cost');
    my $tasks = Task->selectall_arrayref;
    ok(@$tasks, 'selected all tasks');
    my $employees = Employee->selectall_arrayref;
    ok(@$employees, 'selected all employees');

    ## register a task rate
    my $i = 0;
    for my $t (@$tasks){
        for my $e (@$employees){
            Task_cost->insert(+{ emp_id => $e->emp_id, tsk_name => $t->tsk_name, rate => $i++ })->insert;
        }
    }
    ok(count_table('task_cost') == (@$tasks * @$employees), 'verify task_cost row count');

# insert using expressions
    ok(truncate_table('task_cost'), 'clear table task_cost');
    $tasks = Task->selectall_arrayref;
    ok(@$tasks, 'selected all tasks');
    $employees = Employee->selectall_arrayref;
    ok(@$employees, 'selected all employees');

    ## register a task rate
    $i = 0;
    for my $t (@$tasks){
        for my $e (@$employees){
            Task_cost->insert(qw(emp_id tsk_name rate))->values(PlaceHolder,PlaceHolder,expr('2*3'))->prepare->execute($e->emp_id, $t->tsk_name);
        }
    }
    ok(count_table('task_cost') == (@$tasks * @$employees), 'verify task_cost row count');

# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
