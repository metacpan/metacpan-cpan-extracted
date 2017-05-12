package main;
use Test::More tests => 42;
use strict;
use warnings;
use Cwd;

my $sql_i = 0;

BEGIN {
        use_ok('DBI');
        use_ok('DBomb');
        use_ok('DBomb::Query');
        use_ok('DBomb::Test::Util',qw(:all));
        use_ok('DBomb::Test::Objects');
};

## Connect
my $dbh;
ok($dbh = DBI->connect(undef,undef,undef,+{RaiseError=>1, PrintError=>1}), 'connect to database');
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
__PACKAGE__->def_accessor('cli_id', +{ is_generated => 1});
__PACKAGE__->def_primary_key('cli_id');
__PACKAGE__->def_accessor('name');
__PACKAGE__->def_has_many('projects','project',[qw(cli_id)],[qw(cli_id)]);

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
__PACKAGE__->def_accessor('prj_id');
__PACKAGE__->def_accessor('max_hours');
__PACKAGE__->def_primary_key([qw(emp_id prj_id)]);
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
__PACKAGE__->def_accessor('emp_id', +{ is_generated => 1} );
__PACKAGE__->def_primary_key('emp_id');
__PACKAGE__->def_accessor('name');
__PACKAGE__->def_accessor('title');
__PACKAGE__->def_accessor('mgr');

__PACKAGE__->def_has_many('projects', 'project', new DBomb::Query('prj_id')->from('emp_prj')
                                     ->where({'emp_id'=>'?'}), sub{shift->emp_id});
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
__PACKAGE__->def_accessor('prj_id');
__PACKAGE__->def_accessor('tsk_name');
__PACKAGE__->def_accessor('begin_time');
__PACKAGE__->def_accessor('end_time');
__PACKAGE__->def_primary_key([qw(emp_id prj_id tsk_name begin_time)]);

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
__PACKAGE__->def_accessor('prj_id', +{ is_generated => 1});
__PACKAGE__->def_accessor('name');
__PACKAGE__->def_accessor('cli_id');
__PACKAGE__->def_accessor('max_hours');
__PACKAGE__->def_primary_key('prj_id');
__PACKAGE__->def_key(['cli_id']);
__PACKAGE__->def_has_a ('client2', 'client');
__PACKAGE__->def_has_a ('client', ['cli_id'], 'client', ['cli_id']);

__PACKAGE__->def_select_group([qw(prj_id name cli_id max_hours)]);

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

#####################################################################
##
## -- main --
##
#####################################################################
package main;
use strict;
use warnings;
use Carp qw(croak);

$SIG{__DIE__} = sub { croak @_ };
eval   { DBomb->resolve };
if ($@){ diag($@); fail('DBomb->resolve') }
else   { pass('DBomb->resolve'); }

my ($q,$r1,$r2);

## select
ok($q = Client->select, 'Client select');
ok($q = Emp_prj->select, 'Emp_prj select');
ok($q = Employee->select, 'Employee select');
ok($q = Hours->select, 'Hours select');
ok($q = Project->select, 'Project select');
ok($q = Task->select, 'Task select');
ok($q = Task_cost->select, 'Task_cost select');


## selectall_arrayref
ok($q = Client->selectall_arrayref($dbh), 'Client selectall_arrayref');
ok($q = Emp_prj->selectall_arrayref($dbh), 'Emp_prj selectall_arrayref');
ok($q = Employee->selectall_arrayref($dbh), 'Employee selectall_arrayref');
ok($q = Hours->selectall_arrayref($dbh), 'Hours selectall_arrayref');
ok($q = Project->selectall_arrayref($dbh), 'Project selectall_arrayref');
ok($q = Task->selectall_arrayref($dbh), 'Task selectall_arrayref');
ok($q = Task_cost->selectall_arrayref($dbh), 'Task_cost selectall_arrayref');

## select some data with DBomb and with DBI, and verify that the results are the same.
$r1 = $dbh->selectall_arrayref("SELECT name FROM client ORDER BY name ASC");
$r2 = Client->select()->order_by('name')->asc->selectall_arrayref($dbh);

ok(defined($r1) && ref($r1) eq 'ARRAY', 'client DBI data defined');
ok(defined($r2) && ref($r2) eq 'ARRAY', 'client DBomb obj defined');
ok(@$r1 == @$r2, 'client data same row count');
eval {
    for (@$r2) {
        $_->name;
    }
};
ok(!$@, 'auto select name');
ok((0 == grep{$r1->[$_]->[0] ne $r2->[$_]->name} (0..$#$r1)), 'client data match');


## test the foreign_key cruft

## Project has_a client
    my ($projects, $proj_cli) = ([],[]);
    $projects = Project->select->order_by('prj_id')->selectall_arrayref($dbh);

        for (@$projects){
            my $client = $_->client;
            push @$proj_cli, $client->name; ## trigger a fetch of the name
        }
    ok(@$proj_cli == @$projects,'autofetch foreign key object');

    ## verify that the client list is identical to the one we get directly
    my $proj_cli_names= $dbh->selectcol_arrayref(
            "SELECT client.name FROM client JOIN project USING (cli_id) ORDER BY prj_id");

    ok(@$proj_cli == @$proj_cli_names, 'client lists have same length');
    eval{ for my $i (0..@$proj_cli-1){
            $proj_cli->[$i] eq $proj_cli_names->[$i] or die 'client names mismatch'
          }
    };
    if ($@){ diag($@); fail('client names match') }
    else   { pass('client names match') }


## update a foreign key column
    ## create a new project
    my $prj_name = 'Fancy Pants';
    my $clients = Client->select->limit(2)->selectall_arrayref($dbh); # grab the first two clients
    ok($clients->[0]->cli_id != $clients->[1]->cli_id, 'grabbed two arbitrary clients');
    ok($dbh->do("INSERT INTO project (name,cli_id,max_hours) VALUES(?,?,43)", +{}, $prj_name, $clients->[0]->cli_id),'insert new project');

    ## Fetch the project object
    my $proj = Project->select->where(+{name => '?'}, $prj_name)->execute($dbh)->fetch;
    ok($proj->client->cli_id == $clients->[0]->cli_id, 'foreign key object matched');

    ## Update the foreign key column
    ok($proj->cli_id($clients->[1]->cli_id) == $clients->[1]->cli_id, "changed cli_id of the project");
    ok($proj->client->cli_id == $clients->[1]->cli_id, 'new cli_id matched');

    $dbh->do("DELETE FROM project WHERE name = ?",+{},$prj_name);


## Client has_many projects
    ## Grab all the clients
    $clients = Client->select->order_by('cli_id')->selectall_arrayref($dbh);

    ## Just look at clients->[0]
    my $client = $clients->[0];
    $projects = $client->projects;
    ok(defined($projects) && ref($projects), "grabbed has_many projects");

    ## sort by id
    $projects = [ sort {$a->prj_id <=> $b->prj_id} @$projects ];

    ## Verify them
    my $prj_names = $dbh->selectcol_arrayref("SELECT project.name FROM project JOIN client  USING(cli_id) WHERE client.cli_id = ? ORDER BY project.prj_id", {},$client->cli_id);
    ok(@$prj_names == @$projects, 'project list has correct row count');
    my $ix = 0;
    for my $prj_name (@$prj_names){
        last if $prj_name ne $projects->[$ix]->name;
    }continue{$ix++}
    ok($ix == @$prj_names, 'project names matched');

    ## now do the same as above for ALL clients
    for my $client (@$clients){
        $projects = $client->projects;
        defined($projects) && ref($projects) or die "failed to grab has_many projects";

        ## sort by id
        $projects = [ sort {$a->prj_id <=> $b->prj_id} @$projects ];

        ## Verify them
        my $prj_names = $dbh->selectcol_arrayref("SELECT project.name FROM project JOIN client  USING(cli_id) WHERE client.cli_id = ? ORDER BY project.prj_id", {},$client->cli_id);
        @$prj_names == @$projects or die 'project list has incorrect row count';
        my $ix = 0;
        for my $prj_name (@$prj_names){
            last if $prj_name ne $projects->[$ix]->name;
        }continue{$ix++}
        $ix == @$prj_names or die "project names did not match at ix=$ix";
    }

## Employee has a query-based list of projects...

    ## Get some employees
    my $employee_ids= $dbh->selectcol_arrayref("SELECT emp_id, COUNT(prj_id) as cnt FROM emp_prj GROUP BY emp_id ORDER BY cnt DESC");
    ok(@$employee_ids, 'selected employee ids');

    ## check the projects of the first employee
    my $emp = new Employee($employee_ids->[0]);
    $prj_names = $dbh->selectcol_arrayref("SELECT DISTINCT name FROM project JOIN emp_prj USING (prj_id) WHERE emp_id = ? ORDER BY project.prj_id", {},$emp->emp_id);
    ok(@$prj_names, 'fetched project names via DBI');
    $projects = $emp->projects;
    ok(@$projects, 'fetched projects for specific employee');
    ok(@$projects == @$prj_names, 'project lists have same count');
    $ix = 0;
    for (@$prj_names){
        last if $_ ne $projects->[$ix]->name;
    }continue{$ix++}
    ok($ix == @$prj_names, 'project names matched');

1;
# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
