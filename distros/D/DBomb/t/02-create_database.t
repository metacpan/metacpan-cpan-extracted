## Creates tables in the test database used by the rest of the tests.
use Test::More tests => 99;

my %schema = (

    'employee' => q{    emp_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
                        name CHAR(30) NOT NULL,
                        title CHAR(30) NOT NULL,
                        mgr INT NULL,
                        FOREIGN KEY(mgr) REFERENCES employee(emp_id),
                  },

    'client'  => q{     cli_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
                        name CHAR(30) NOT NULL,
                 },

    'project' => q{     prj_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
                        name char(30) NOT NULL,
                        cli_id INT NOT NULL,
                        max_hours INT NOT NULL,
                        FOREIGN KEY(cli_id) REFERENCES client(cli_id),
                  },

    'emp_prj' => q{
                        emp_id  INT NOT NULL,
                        prj_id INT NOT NULL,
                        max_hours INT NOT NULL,
                        PRIMARY KEY(emp_id,prj_id),
                        FOREIGN KEY(emp_id) REFERENCES employee(emp_id),
                        FOREIGN KEY(prj_id) REFERENCES project(prj_id),
                   },

    'task' => q{        tsk_name  CHAR(20) NOT NULL,
                        PRIMARY KEY(tsk_name),
                },

    'task_cost' => q{   emp_id   INT NOT NULL,
                        tsk_name  CHAR(20) NOT NULL,
                        rate   DECIMAL(8,3) NOT NULL,
                        PRIMARY KEY(emp_id,tsk_name),
                        FOREIGN KEY(emp_id) REFERENCES employee(emp_id),
                        FOREIGN KEY(tsk_name) REFERENCES task(tsk_name),
               },

    'hours'   =>   q{   emp_id  INT NOT NULL,
                        prj_id  INT NOT NULL,
                        tsk_name  CHAR(20) NOT NULL,
                        begin_time  DATETIME NOT NULL,
                        end_time    DATETIME NOT NULL,
                        PRIMARY KEY(emp_id,prj_id,tsk_name,begin_time),
                        FOREIGN KEY(emp_id) REFERENCES employee(emp_id),
                        FOREIGN KEY(prj_id) REFERENCES project(prj_id),
                        FOREIGN KEY(tsk_name) REFERENCES task(tsk_name),
                    },
);

my @insert_data = (
    ## Mgmt heirarchy: Alison manages [Beatrice, Cynthia, Dot], who manage everyone else.
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Alison',  'CEO', NULL)}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Beatrice','CTO', ?)}, sub{get_empid('Alison')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Cynthia', 'CFO', ?)}, sub{get_empid('Alison')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Dot',     'President', ?)}, sub{get_empid('Alison')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Elanor',  'VP', ?)}, sub{get_empid('Dot')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Frida',   'Accountant', ?)}, sub{get_empid('Cynthia')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Gabrielle','Proj Mgr', ?)}, sub{get_empid('Elanor')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Holly',    'Proj Mgr', ?)}, sub{get_empid('Elanor')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Isabelle', 'Proj Mgr', ?)}, sub{get_empid('Elanor')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Jaqueline','Lead Programmer', ?)}, sub{get_empid('Gabrielle')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Karin',    'Programmer', ?)}, sub{get_empid('Gabrielle')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Leah',     'Programmer', ?)}, sub{get_empid('Gabrielle')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Marissa',  'Lead Programmer', ?)}, sub{get_empid('Holly')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Neepa',    'Programmer', ?)}, sub{get_empid('Holly')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Ophelia',   'Programmer', ?)}, sub{get_empid('Holly')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Penelope',  'Lead Programmer', ?)}, sub{get_empid('Isabelle')}],
    [q{INSERT INTO employee (name,title,mgr) VALUES ('Quentina',  'Programmer', ?)}, sub{get_empid('Isabelle')}],

    ## Possible tasks
    (map {+["INSERT INTO task (tsk_name) VAlUES ('$_')"]} qw(
            negotiation
            planning
            research
            design
            coding
            testing
            bug-fixing)),

    ## Clients
    (map {["INSERT INTO client (name) VALUES ('$_')"]} qw(Sun Oracle)),

    ## Projects
    [q{INSERT INTO project (name,cli_id,max_hours) VALUES ('Ultra DB',    ?,100)}, sub{get_cliid('Oracle')}],
    [q{INSERT INTO project (name,cli_id,max_hours) VALUES ('Mega Modeler',?,200)}, sub{get_cliid('Oracle')}],
    [q{INSERT INTO project (name,cli_id,max_hours) VALUES ('JavaCrap(tm)',?,900)}, sub{get_cliid('Sun')}],
    [q{INSERT INTO project (name,cli_id,max_hours) VALUES ('Solarisbot',  ?,72)},  sub{get_cliid('Sun')}],


    ## Employee/Project map.
    (map { my($e,$p,$h)=@$_;
          ["INSERT INTO emp_prj (emp_id,prj_id,max_hours) VALUES (?,?,?)",sub{get_empid($e)},sub{get_prjid($p)},$h]}
        (
          [ Gabrielle => 'Ultra DB', 30],
          [ Jaqueline => 'Ultra DB', 30],
          [ Karin     => 'Ultra DB', 20],
          [ Leah      => 'Ultra DB', 20],
          [ Holly     => 'Mega Modeler', 50],
          [ Marissa   => 'Mega Modeler', 50],
          [ Neepa     => 'Mega Modeler', 50],
          [ Ophelia   => 'Mega Modeler', 50],
          [ Isabelle  => 'Solarisbot', 24],
          [ Penelope  => 'Solarisbot', 24],
          [ Quentina  => 'Solarisbot', 24]
        )),

    ## a few employees work on more than one project
    (map { my($e,$p,$h)=@$_;
          ["INSERT INTO emp_prj (emp_id,prj_id,max_hours) VALUES (?,?,?)",sub{get_empid($e)},sub{get_prjid($p)},$h]}
        (
          [ Neepa  => 'Ultra DB', 2],
          [ Neepa  => 'Solarisbot', 24],
          [ Karin  => 'Mega Modeler', 50],
          [ Karin  => 'Solarisbot', 24],
        )),

    ## Hours
    (map {my $a=$_;
          ["INSERT INTO hours (emp_id,prj_id,tsk_name,begin_time,end_time) VALUES (?,?,?,?,?)",
            sub{get_empid($$a[0])}, sub{get_prjid($$a[1])}, @$a[2..$#$a]]} (
          # Ultra DB is over time budget
          [ Gabrielle => 'Ultra DB',     'design',   "2003-09-01 09:00:00", "2003-09-01 17:00:00"],
          [ Gabrielle => 'Ultra DB',     'design',   "2003-09-02 09:00:00", "2003-09-02 17:00:00"],
          [ Gabrielle => 'Ultra DB',     'design',   "2003-09-03 09:00:00", "2003-09-03 17:00:00"],
          [ Gabrielle => 'Ultra DB',     'design',   "2003-09-04 09:00:00", "2003-09-04 17:00:00"],
          [ Jaqueline => 'Ultra DB',     'design',   "2003-09-01 09:00:00", "2003-09-01 17:00:00"],
          [ Jaqueline => 'Ultra DB',     'design',   "2003-09-02 09:00:00", "2003-09-02 17:00:00"],
          [ Jaqueline => 'Ultra DB',     'design',   "2003-09-03 09:00:00", "2003-09-03 17:00:00"],
          [ Jaqueline => 'Ultra DB',     'design',   "2003-09-04 09:00:00", "2003-09-04 17:00:00"],
          [ Karin     => 'Ultra DB',     'coding',   "2003-09-05 09:00:00", "2003-09-05 17:00:00"],
          [ Karin     => 'Ultra DB',     'coding',   "2003-09-08 09:00:00", "2003-09-08 17:00:00"],
          [ Karin     => 'Ultra DB',     'coding',   "2003-09-09 09:00:00", "2003-09-09 17:00:00"],
          [ Leah      => 'Ultra DB',     'coding',   "2003-09-05 09:00:00", "2003-09-05 17:00:00"],
          [ Leah      => 'Ultra DB',     'coding',   "2003-09-08 09:00:00", "2003-09-08 17:00:00"],
          [ Leah      => 'Ultra DB',     'coding',   "2003-09-09 09:00:00", "2003-09-09 17:00:00"],

           # Mega Modeler is under time budget
          [ Holly     => 'Mega Modeler', 'planning', "2003-09-01 09:00:00", "2003-09-01 17:00:00"],
          [ Holly     => 'Mega Modeler', 'planning', "2003-09-02 09:00:00", "2003-09-02 17:00:00"],
          [ Holly     => 'Mega Modeler', 'design',   "2003-09-03 09:00:00", "2003-09-03 17:00:00"],
          [ Holly     => 'Mega Modeler', 'design',   "2003-09-04 09:00:00", "2003-09-04 17:00:00"],
          [ Holly     => 'Mega Modeler', 'design',   "2003-09-05 09:00:00", "2003-09-05 17:00:00"],
          [ Marissa   => 'Mega Modeler', 'planning', "2003-09-01 09:00:00", "2003-09-01 17:00:00"],
          [ Marissa   => 'Mega Modeler', 'planning', "2003-09-02 09:00:00", "2003-09-02 17:00:00"],
          [ Marissa   => 'Mega Modeler', 'design',   "2003-09-03 09:00:00", "2003-09-03 17:00:00"],
          [ Marissa   => 'Mega Modeler', 'design',   "2003-09-04 09:00:00", "2003-09-04 17:00:00"],
          [ Marissa   => 'Mega Modeler', 'design',   "2003-09-05 09:00:00", "2003-09-05 17:00:00"],
          [ Neepa     => 'Mega Modeler', 'coding',   "2003-09-08 09:00:00", "2003-09-08 17:00:00"],
          [ Neepa     => 'Mega Modeler', 'coding',   "2003-09-09 09:00:00", "2003-09-09 17:00:00"],
          [ Neepa     => 'Mega Modeler', 'coding',   "2003-09-10 09:00:00", "2003-09-10 17:00:00"],
          [ Neepa     => 'Mega Modeler', 'coding',   "2003-09-11 09:00:00", "2003-09-11 17:00:00"],
          [ Neepa     => 'Mega Modeler', 'coding',   "2003-09-12 09:00:00", "2003-09-12 17:00:00"],
          [ Ophelia   => 'Mega Modeler', 'coding',   "2003-09-08 09:00:00", "2003-09-08 17:00:00"],
          [ Ophelia   => 'Mega Modeler', 'coding',   "2003-09-09 09:00:00", "2003-09-09 17:00:00"],
          [ Ophelia   => 'Mega Modeler', 'coding',   "2003-09-10 09:00:00", "2003-09-10 17:00:00"],
          [ Ophelia   => 'Mega Modeler', 'coding',   "2003-09-11 09:00:00", "2003-09-11 17:00:00"],
          [ Ophelia   => 'Mega Modeler', 'coding',   "2003-09-12 09:00:00", "2003-09-12 17:00:00"],

          # Solarisbot is right on budget
          [ Isabelle  => 'Solarisbot',   'planning', "2003-09-01 09:00:00", "2003-09-01 17:00:00"],
          [ Isabelle  => 'Solarisbot',   'design',   "2003-09-02 09:00:00", "2003-09-02 17:00:00"],
          [ Isabelle  => 'Solarisbot',   'design',   "2003-09-03 09:00:00", "2003-09-03 17:00:00"],
          [ Penelope  => 'Solarisbot',   'planning', "2003-09-01 09:00:00", "2003-09-01 17:00:00"],
          [ Penelope  => 'Solarisbot',   'design',   "2003-09-02 09:00:00", "2003-09-02 17:00:00"],
          [ Penelope  => 'Solarisbot',   'design',   "2003-09-03 09:00:00", "2003-09-03 17:00:00"],
          [ Quentina  => 'Solarisbot',   'coding',   "2003-09-04 09:00:00", "2003-09-04 17:00:00"],
          [ Quentina  => 'Solarisbot',   'coding',   "2003-09-05 09:00:00", "2003-09-05 17:00:00"],
          [ Quentina  => 'Solarisbot',   'coding',   "2003-09-08 09:00:00", "2003-09-08 17:00:00"],
        )),

);



BEGIN {
        use_ok('DBI');
        use_ok('DBomb');
        use_ok('DBomb::Query');
};

## Connect to database
my $dbh;
ok($dbh = DBI->connect(undef,undef,undef,+{RaiseError=>1, PrintError=>1}), 'connect to database');

create_database(1);
populate_database(1);

##
## SUBROUTINES
##

## Create all the tables.
## create_database($call_ok)
sub create_database
{
    my $ok = $_[0] ? \&Test::More::ok : sub { };

    while ( my($table, $sql) = each %schema ){

        eval{
              ## Doesn't matter if the DROP fails. Disable errors.
              local $dbh->{RaiseError};
              local $dbh->{PrintError};
              $dbh->do("DROP TABLE $table");
        };

        $ok->( defined($dbh->do("CREATE TABLE $table ( $sql )")), "CREATE TABLE $table");
    }
}

## Populate the database
## populate_database($call_ok)
sub populate_database
{
    my $ok = $_[0] ? \&Test::More::ok : sub { };

    for (@insert_data){
        my ($sql, @binds ) = @$_;
        my @binds = map { ref($_) ? $_->() : $_ } @binds;
        my $msg = "SQL: $sql -- [@{[join q(,), map{defined($_)?$_:q(undef)}@binds]}]";
        eval { $dbh->do($sql,+{}, @binds) };
        print STDERR "$msg\n" if $@;
        $ok->(!$@, $msg);
    }
}


sub get_empid
{
    my $name = shift;
    my $row = get_val('employee', ['emp_id'], "name = ?", $name);
    die "Could not find emp_id for employee named '$name'!" unless @$row;
    return $row->[0];
}

sub get_cliid
{
    my $name = shift;
    my $row = get_val('client', ['cli_id'], "name = ?", $name);
    die "Could not find cli_id for client named '$name!" unless @$row;
    return $row->[0];
}


sub get_prjid
{
    my $name = shift;
    my $row = get_val('project', ['prj_id'], "name = ?", $name);
    die "Could not find prj_id for project named '$name!" unless @$row;
    return $row->[0];
}


sub get_val
{
    my($table,$columns,$where, @bind) = @_;
    my $sql = "SELECT @{[join ',',@$columns]} FROM  $table WHERE $where";
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    return $sth->fetchrow_arrayref;
}

sub last_id
{
    return scalar $dbh->{'mysql_insertid'};
}
