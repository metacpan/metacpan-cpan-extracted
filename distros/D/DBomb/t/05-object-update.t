package main;
use Test::More tests => 22;
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
        use_ok('DBomb::Query::Expr',qw(expr));
};

## Connect
my ($dbh);
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
__PACKAGE__->def_accessor('cli_id');
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
__PACKAGE__->def_accessor('emp_id');
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

##$SIG{__DIE__} = sub { croak @_ };

my ($q);

## Reset client names to lower case, then to upper case through DBomb
    $dbh->do("UPDATE client SET name = LOWER(name)");
    ok($q = Client->selectall_arrayref($dbh), 'Client selectall_arrayref');

    for (@$q){
        my $n = $_->name;
        $_->name(uc $n);
        $_->update;
    }
    pass("update Client uc name");
    ## Now verify that they are actually uppercase!
    $q = $dbh->selectcol_arrayref("SELECT name FROM client");
    ok(@$q == scalar(grep{ $_ eq uc $_} @$q), 'verify names are now uc');


## Same as last test, but multiple columns
    $dbh->do("UPDATE employee SET name = LOWER(name), title = LOWER(title)");
    ok($q = Employee->selectall_arrayref($dbh), 'Employee selectall_arrayref');

    for (@$q){
        my $n = $_->name;
        my $t = $_->title;
        $_->name(uc $n);
        $_->title(uc $t);
        $_->update;
    }
    pass("update Employee uc name and title");
    ## Now verify that they are actually uppercase!
    $q = $dbh->selectall_arrayref("SELECT name,title FROM employee");
    ok(2 * @$q == scalar(grep{ $_ eq uc $_ } map {(@$_)} @$q), 'verify names are now uc');

##
## Class methods
##

## Reset client names to lower case, then to upper case through DBomb
    $dbh->do("UPDATE client SET name = LOWER(name)");
    ok($q = Client->selectall_arrayref($dbh), 'Client selectall_arrayref');

    for (@$q){
        my $n = $_->name;
        my $update = Client->update;
        $update->set('name', uc $n);
        $update->where({name => '?'}, $_->name);
        $update->update;
    }
    pass("update Client uc name");
    ## Now verify that they are actually uppercase!
    $q = $dbh->selectcol_arrayref("SELECT name FROM client");
    ok(@$q == scalar(grep{ $_ eq uc $_} @$q), 'verify names and titles are now uc');


## Same as last test, but multiple columns
    $dbh->do("UPDATE employee SET name = LOWER(name), title = LOWER(title)");
    ok($q = Employee->selectall_arrayref($dbh), 'Employee selectall_arrayref');

    my $ok = 0;
    for (@$q){
        $ok = 0;
        my $n = $_->name;
        my $t = $_->title;
        my $update = Employee->update;
        $update->set({name => uc($n), title => uc($t)})->where({emp_id => $_->emp_id});
        $update->update || last;
    }continue{$ok = 1}
    ok($ok,"update Employee uc name and title");

    ## Now verify that they are actually uppercase!
    $q = $dbh->selectall_arrayref("SELECT name,title FROM employee");
    ok(2 * @$q == scalar(grep{ $_ eq uc $_ } map {(@$_)} @$q), 'verify names are now uc');

## update every row all at once without a where clause
    $dbh->do("UPDATE employee SET name = LOWER(name), title = LOWER(title)");
    ok($q = Employee->selectall_arrayref($dbh), 'Employee selectall_arrayref');

    ok(Employee->update->set({name => expr('UPPER(name)'), title => expr('UPPER(title)')})->update,
        "update Employee uc name and title");

    ## Now verify that they are actually uppercase!
    $q = $dbh->selectall_arrayref("SELECT name,title FROM employee");
    ok(2 * @$q == scalar(grep{ $_ eq uc $_ } map {(@$_)} @$q), 'verify names and titles are now uc');

# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
