package DBIx::Connection;

use warnings;
use strict;
use DBI;
use DBI::Const::GetInfoType;
use Abstract::Meta::Class ':all';
use DBIx::SQLHandler;
use DBIx::QueryCursor;
use Carp 'confess';
use vars qw($VERSION $CONNECTION_POOLING $IDLE_THRESHOLD);
use Time::HiRes qw(gettimeofday tv_interval);

$VERSION = 0.08;
$IDLE_THRESHOLD = 300;

=head1 NAME

DBIx::Connection - Simple database interface.

=head1 SYNOPSIS

    use DBIx::Connection;
    my $connection = DBIx::Connection->new(
      name                 => 'my_connection_name',
      dsn                  => 'dbi:Oracle:localhost:1521/ORCL',
      username             => 'user',
      password             => 'password',
      db_session_variables => {
        NLS_DATE_FORMAT => 'DD.MM.YYYY'
      }
    );

    or
    my $dbh = DBI->connect(...);
    my $connection = DBIx::Connection->new(
      name  => 'my_connection_name',
      dbh   => $dbh,
      db_session_variables => {
        NLS_DATE_FORMAT => 'DD.MM.YYYY'
      }
    );    


    my $cursor = $connection->query_cursor(sql => "select * from emp where deptno > ?", name => 'emp_select');
    my $dataset = $cursor->execute(20);
    while ($cursor->fetch) {
        #do some stuff ...
        print $_ . " => " . $dataset->{$_}
          for keys %$dataset;
    }

    {
        my $cursor = $connection->find_query_cursor('emp_select');
        my $dataset = $cursor->execute(20);
        ...
    }


    my $record = $connection->record("select * from emp where empno = ?", 'xxx');

    my $sql_handler = $connection->sql_handler(sql => "INSERT INTO emp(empno, ename) VALUES(?, ?)", name => 'emp_ins');
    $sql_handler->execute(1, 'Smith');
    $sql_handler->execute(2, 'Witek');

    {
        my $sql_handler= $connection->find_sql_handler('emp_ins');
        $sql_handler->execute(3, 'Zzz');
        ...
    }

    #or

    $connection->execute_statement("INSERT INTO emp(empno, ename) VALUES(?, ?)", 1, 'Smith');



    #gets connection by name.
    my $connection = DBIx::Connection->connection('my_connection_name');

    do stuff

    # returns connection to connection pool
    $connection->close();


    #turn on connection pooling
    $DBIx::Connection::CONNECTION_POOLING = 1;

    In this mode only connection may have the following states : in_use and NOT in_use,
    Only connection that is "NOT in use" state can be retrieve by invoking DBIx::Connection->connection, and
    state changes to "in use".  Close method change state back to NOT in_use.
    If in connection pool there are not connections in "NOT in use" state, then the new connection is cloned.

    my $connection = DBIx::Connection->connection('my_connection_name');


    # do stuff ...
    $connection->close();

    #preserving resource by physical disconnecting all connection that are idle by defined threshold (sec).
    $DBIx::Connection::IDLE_THRESHOLD = 300;


=head1 DESCRIPTION

Represents a database connection handler.

It provides simple interface to managing database connections with the all related operations wrapped in the
different sql handlers.

    $connection = DBIx::Connection->connection('my_connection_name');

    eval {
        $connection->begin_work();
        my $sql_handler = $connection->sql_handler(sql => "INSERT INTO emp(empno, ename) VALUES(?, ?)");
        $sql_handler->execute(1, 'Smith');
        ...

        $connection->commit();
    };

    if($@) {
        $connection->rollback();
    }

    $connection->close();

It supports:

sql handlers(dml) -(INSERT/UDPDATE/DELETE)

    my $sql_handler = $connection->sql_handler(sql => "INSERT INTO emp(empno, ename) VALUES(?, ?)");
    $sql_handler->execute(1, 'Smith');

query cursors - SELECT ... FROM ...

    my $query_cursor = $connection->query_cursor(
        sql        => "
        SELECT t.* FROM (
        SELECT 1 AS col1, 'text 1' AS col2 " . ($dialect eq 'oracle' ? ' FROM dual' : '') . "
        UNION ALL
        SELECT 2 AS col1, 'text 2' AS col2 " . ($dialect eq 'oracle' ? ' FROM  dual' : '') . "
        ) t
        WHERE 1 = ? "
    );
    my $resultset = $cursor->execute([1]);
    while($cursor->fetch()) {
       # do some stuff
       # $resultset 
    }

plsql handlers - BEGIN ... END

    my $plsql_handler = $connection->plsql_handler(
        name        => 'test_block',
        connection  => $connection,
        plsql       => "BEGIN
        :var1 := :var2 + :var3;
        END;",
        bind_variables => {
            var1 => {type => 'SQL_INTEGER'},
            var2 => {type => 'SQL_INTEGER'},
            var3 => {type => 'SQL_INTEGER'}
        }
    );
    my $resultset = $plsql_handler->execute(var2 => 12, var3 => 8);


Connection is cached by its name.

    DBIx::Connection->new(
        name                 => 'my_connection_name',
        dsn                  => 'dbi:Oracle:localhost:1521/ORCL',
        username             => 'user',
        password             => 'password',
    );

    $connection = DBIx::Connection->connection('my_connection_name');

RDBMS session variables supports.

    my $databaseHandler = DBIx::Connection->new(
        name                 => 'my_connection_name',
        dsn                  => 'dbi:Oracle:localhost:1521/ORCL',
        username             => 'user',
        password             => 'password',
        db_session_variables => {
            NLS_DATE_FORMAT => 'DD.MM.YYYY'
        }
    )

It caches sql statements based on handler's name.

    $connection->sql_handler(name => 'emp_ins', sql => "INSERT INTO emp(empno, ename) VALUES(?, ?)");
    my $sql_handler = $connection->find_sql_handler('emp_ins');
    $sql_handler->execute(1, 'Smith');


Database usage:

This module allows gathering sql statistics issued by application

Automatic reporting:

    $connection->set_collect_statistics(1);
    $connection->set_statistics_dir('/sql_usage');


Error handler customization:

It supports eroror handler customization.

    my $error_handler = sub {
        my (self, $message, $sql_handler) = @_;
        #do some stuff
    };
    $connection->set_custom_error_handler($error_handler);


Sequences support:

    $connection->sequence_value('emp_seq');

Large Object support;

    $connection->update_lob(lob_test => 'blob_content', $lob_content,  {id => 1}, 'doc_size');
    my $lob = $connection->fetch_lob(lob_test => 'blob_content', {id => 1}, 'doc_size');


=head2 ATTRIBUTES

=over

=item name

Connection name.

=cut

has '$.name';


=item dsn

Database source name.

=cut

has '$.dsn';


=item username

=cut

has '$.username';


=item password

=cut

has '$.password';


=item database handler

=cut

has '$.dbh';


=item db_session_variables

=cut

has '%.db_session_variables';


=item query_cursors

=cut

has '%.query_cursors' => (item_accessor => '_query_cursor');


=item sql_handlers

=cut

has '%.sql_handlers' => (item_accessor => '_sql_handler');



=item plsql_handlers

=cut

has '%.plsql_handlers' => (item_accessor => '_plsql_handler');


=item custom_error_handler

Callback that overwrites default error_handler on SQLHandler object.

=cut

has '&.custom_error_handler';


=item stats

=cut

has '%.tracking';


=item action_start_time

=cut

has '$.action_start_time';


=item collect_statistics

Flag that indicate if statisitcs are collected.

=cut

has '$.collect_statistics' => (default => 0);


=item statistics_dir

=cut

has '$.statistics_dir';


=item in_use

=cut

has '$.in_use';



=item is_connected

=cut

has '$.is_connected';


=item last_in_use

=cut

has '$.last_in_use';



=item no_cache

Prepares statements each time, otherwise use prepare statement once and reuse it

=cut

has '$.no_cache';


=item _active_transaction

Flag that indicate that connection has pending transaction

=cut

has '$._active_transaction';


=back

=head2 METHODS

=over

=item load_module

Loads specyfic rdbms module.

=cut

{
    my %loaded_modules = ();
    sub load_module {
        my ($self, $module) = @_;
        my $rdbms_module = $self->dbms_name . "::" . $module;
        return $loaded_modules{$rdbms_module} if $loaded_modules{$rdbms_module};
        my $module_name = __PACKAGE__ . "::\u$rdbms_module";
        my $module_to_load =  $module_name;
        $module_to_load =~ s/::/\//g;
        eval { require "${module_to_load}.pm" };
        return if $@;
        $loaded_modules{$rdbms_module} = $module_name;
        $module_name;
    }
}

=item connect

Connects to the database.

=cut

sub connect {
    my ($self) = @_;
    my $dbh = DBI->connect(
      $self->dsn,
      $self->username,
      $self->password,
      { PrintError => 0, AutoCommit => 1},
    ) or $self->error_handler("Cannot connect to database " . $self->dsn . " " . $DBI::errstr);
    $dbh->{Warn} = 0;
    $self->set_dbh($dbh);
    $self->is_connected(1);
}


=item check_connection

Checks the database connection and reconnects if necessary.

=cut

sub check_connection {
    my ($self) = @_;
    unless (eval { $self->dbh->ping }) {
        warn "Database disconnected, reconnecting\n";
        $self->connect;
    }
}


=item do

Executes passed in sql statement.

=cut

sub do {
    my ($self, $sql) = @_;
    $self->record_action_start_time;
    $self->dbh->do($sql) 
      or $self->error_handler($sql);
    $self->record_action_end_time($sql, 'execute');   
}


=item sql_handler

Returns a new sql handeler instance.

    my $sql_handler = $connection->sql_handler(
        name => 'emp_ins'
        sql => "INSERT INTO emp(empno, ename) VALUES(?, ?)",
    );
    $sql_handler->execute(1, 'Smith');

=cut

sub sql_handler {
    my ($self, %args) = @_;
    my $name = $args{name} || $args{sql};
    my $result  = $self->_sql_handler($name);
    if(! $result || $self->no_cache) {
        $result = DBIx::SQLHandler->new(connection  => $self, %args);
        $self->_sql_handler($name, $result);
    }
    $result;
}


=item find_sql_handler

Returns cached sql handler.
Takes sql handler name as parameter.


    my $sql_handler = $connection->find_sql_handler('emp_ins');
    $sql_handler->execute(1, 'Scott');


=cut

sub find_sql_handler {
    my ($self, $name) = @_;
    $self->_sql_handler($name);
}


=item execute_statement

Executes passed in statement.

    $connection->execute_statement("INSERT INTO emp(empno, ename) VALUES(?, ?)", 1, 'Smith');

=cut

sub execute_statement {
    my ($self, $sql, @bind_variables) = @_;
    my $sql_handler = $self->sql_handler(sql => $sql);
    $sql_handler->execute(@bind_variables);
}


=item query_cursor

        my $cursor = $connection->query_cursor(sql => "SELECT * FROM emp WHERE empno = ?");
        my @result_set;
        $cursor->execute([1], \@result_set);

        or # my $result_set = $cursor->execute([1]);

        my $iterator = $cursor->iterator;
        while($iterator->()) {
           #do some stuff
           #@result_set 
        }

        # or        

        while($cusor->fetch()) {
           #do some stuff
           #@result_set 
        }

=cut

sub query_cursor {
    my ($self, %args) = @_;
    my $name = $args{name} || $args{sql};
    my $result  = $self->_query_cursor($name);
    if(! $result || $self->no_cache) {
        $result = DBIx::QueryCursor->new(connection  => $self, %args);
        $self->_query_cursor($name, $result);
    }
    $result;
}


=item find_query_cursor

Returns cached query cursor.
Takes query cursor name as parmeter.

    my $cursor = $connection->find_query_cursor('my_cusror');
    my $result_set = $cursor->execute([1]);

=cut

sub find_query_cursor {
    my ($self, $name) = @_;
    $self->_query_cursor($name);
}


=item plsql_handler

Returns a new plsql handeler instance <DBIx::PLSQLHandler>.
Takes DBIx::PLSQLHandler constructor parameters.

    my $plsql_handler = $connection->plsql_handler(
        name       => 'my_plsql',
        plsql      => "DECLARE
    debit_amt    CONSTANT NUMBER(5,2) := 500.00;
    BEGIN
        SELECT a.bal INTO :acct_balance FROM accounts a
        WHERE a.account_id = :acct AND a.debit > debit_amt;
        :extra_info := 'debit_amt: ' || debit_amt;
    END;");

    my $result_set = $plsql_handler->execute(acct => 000212);
    print $result_set->{acct_balance};
    print $result_set->{extra_info};

=cut

sub plsql_handler {
    my ($self, %args) = @_;
    my $name = $args{name} || $args{sql};
    my $result  = $self->_plsql_handler($name);
    if(! $result || $self->no_cache) {
        $result = DBIx::PLSQLHandler->new(connection  => $self, %args);
        $self->_plsql_handler($name, $result);
    }
    $result;
    
}


=item find_plsql_handler

Returns cached plsql handler, takes name of handler.

    my $plsql_handler = $connection->find_plsql_handler('my_plsql');
    my $result_set = $plsql_handler->execute(acct => 000212);

=cut

sub find_plsql_handler {
    my ($self, $name) = @_;
    $self->_plsql_handler($name);
}


=item record

Returns resultset record. Takes sql statement, and bind variables parameters as list.

    my $resultset = $connection->record("SELECT * FROM emp WHERE ename = ? AND deptno = ? ", 'scott', 10);
    #$resultset->{ename}
    # do some stuff

=cut

sub record {
    my ($self, $sql, @bind_variables) = @_;
    my $query_cursor = $self->query_cursor(sql => $sql);
    my $result = $query_cursor->execute(\@bind_variables);
    $query_cursor->fetch();
    $result;
}


=item begin_work

Begins transaction.

=cut

sub begin_work {
    my ($self) = @_;
    my $dbh = $self->dbh;
    confess "connection has allready active transaction "
        if $self->_active_transaction;
    $self->_active_transaction(1);
    my $result = $dbh->begin_work() 
      or $self->error_handler("Could not start transaction");
}


=item commit

Commits current transaction.

=cut

sub commit {
    my ($self) = @_;
    my $dbh = $self->dbh;
    $self->_active_transaction(0);
    $dbh->commit() 
      or $self->error_handler("Could not commit current transaction");
}


=item rollback

Rollbacks current transaction.

=cut

sub rollback {
    my ($self) = @_;
    my $dbh = $self->dbh;
    $self->_active_transaction(0);
    $dbh->rollback() 
      or $self->error_handler("Could not rollback current transaction");
}



{
 my %connections;
 my %connections_counter;


=item initialise
 
Initialises connection.

=cut

    sub initialise {
        my ($self) = @_;
        $self->set_name($self->dsn . " " . $self->username) unless $self->name;
        if($self->dbh) {
            $self->is_connected(1);
        } else {
            $self->connect;
        }
        $self->set_session_variables($self->db_session_variables)
            if (keys %{$self->db_session_variables});
        $self->_cache_connection;
    }



=item connection

Returns connection object for passed in connection name.

=cut

    sub  connection {
        my ($class, $name) = @_;
        if(!exists($connections_counter{$name})) {
            die "connection $name does not exist";
        }
        my $result;
        if ($CONNECTION_POOLING) {
            $result = $connections{"${name}_0"}->_find_connection;
            $result->_check_connection;
            $result->last_in_use(time);
            
        } else {
            $result = $connections{"${name}_0"};
        }
        $class->check_connnections;
        $result;
    }


=item has_autocomit_mode

Returns true if connection has autocommit mode

=cut

sub has_autocomit_mode {
    my ($self) = @_;
    !! $self->dbh->{AutoCommit};
}


=item _find_connection

Finds connections

=cut

sub _find_connection {
    my ($self) = @_;
    my $name = $self->name;
    unless ($self->in_use) {
        $self->set_in_use(1);
        return $self;
    }
    my $counter = $connections_counter{$name};
    for my $i(0 .. $counter) {
        my $connection = $connections{"${name}_$i"};
        unless ($connection->in_use) {
            $connection->set_in_use(1);
            return $connection;
        }
    }
    $self->_clone_connection();
}


=item _cache_connection

Checks connection

=cut

    sub _cache_connection {
        my ($self) = @_;
        my $name = $self->name;
        my $counter = exists $connections_counter{$name} ? $connections_counter{$name} + 1 : 0;
        $connections_counter{$name} = $counter;
        $connections{"${name}_${counter}"} = $self;
    }


=item _clone_connection

Clones current connection. Returns a new connection object.

=cut

    sub _clone_connection {
        my ($self) = @_;
        my $connection = __PACKAGE__->new(
            name     => $self->name,
            dsn      => $self->dsn,
            username => $self->username,
            password => $self->password,
        );
        $connection->set_in_use(1);
        $connection;
    }


=item _check_connection

Checks connection state.

=cut

    sub _check_connection {
        my ($self) = @_;
        return $self->connect unless $self->is_connected;
        if($self->_is_idled) {
            $self->check_connection;
        }
    }
    
    
=item _is_idled

returns true if connection is idle.

=cut


    sub _is_idled {
        my $self = shift;
        !! (time - ($self->last_in_use || time)  > $IDLE_THRESHOLD);
    }


=item check_connnections

Checks all connection and disconnects all inactive for longer the 5 mins

=cut

    sub check_connnections {
    my ($class) = @_;
        for my $k(keys %connections) {
            my $connection = $connections{$k};
            $connection->disconnect() if(! $connection->in_use && $connection->_is_idled);
        }
    }
    

=item close

Returns connection to the connection pool,
so that connection may be reused by another call Connection->connection('connection_name')
rather then its clone.

=cut

    sub close {
        my ($self) = @_;
        if ($CONNECTION_POOLING) {
            $self->set_in_use(0);
            $self->last_in_use(time);
        }
    }

}


=item disconnect

Disconnects from current database.

=cut

sub disconnect {
    my ($self) = @_;
    my $dbh = $self->dbh or return;
    $self->set_query_cursors({});
    $self->sql_handlers({});
    $self->is_connected(0);
    $self->dbh->disconnect 
      or $self->error_handler("Can not disconnect from database: $DBI::errstr");
      
}


=item dbms_name

Returns database name

=cut

sub dbms_name {
    my ($self) = @_;
    $self->dbh->get_info($GetInfoType{SQL_DBMS_NAME});
}


=item dbms_version

Returns database version

=cut

sub dbms_version {
    my ($self) = @_;
    $self->dbh->get_info($GetInfoType{SQL_DBMS_VER});
}


=item primary_key_info

Returns primary key information, takes table name
Return array ref (DBI::primary_key_info)

TABLE_CAT: The catalog identifier. This field is NULL (undef) if not applicable to the data source, which is often the case. This field is empty if not applicable to the table.

TABLE_SCHEM: The schema identifier. This field is NULL (undef) if not applicable to the data source, and empty if not applicable to the table.

TABLE_NAME: The table identifier.

COLUMN_NAME: The column identifier.

KEY_SEQ: The column sequence number (starting with 1). Note: This field is named ORDINAL_POSITION in SQL/CLI.

PK_NAME The primary key constraint identifier. This field is NULL (undef) if not applicable to the data source.

=cut

sub primary_key_info {
    my ($self, $table_name, $schema) = @_;
    my $sth = $self->dbh->primary_key_info(undef, $schema, $table_name);
    my $result = $sth ? $sth->fetchall_arrayref : undef;
    if($result && ! @$result) {
        my $module_name = $self->load_module('SQL');
        if($module_name && $module_name->can('primary_key_info')) {
            my $sql = $module_name->primary_key_info($schema);
            my $cursor = $self->query_cursor(sql => $sql);
            my $resultset = $cursor->execute([$table_name, ($schema ? $schema : ())]);
            $result = [];
            while ($cursor->fetch()) {
                push @$result, [undef, $schema, $resultset->{table_name}, $resultset->{column_name}, undef, $resultset->{pk_name}];
            }
        }
    }
    $result;
}


=item primary_key_columns

Returns primary key columns

    my @primary_key_columns = $connection->primary_key_columns('emp');

=cut

sub primary_key_columns {
    my ($self, $table_name) = @_;
    my ($schema, $table) = ($table_name =~ m/([^\.]+)\.(.+)/);
    my $info = $self->primary_key_info($schema ? ($schema, $table) : ($table_name));
    map { $_->[3] } @$info;
}


=item table_info

Returns table info.
See also DBI::table_info

=cut

sub table_info {
    my ($self, $table_name) = @_;
    my $sth = $self->dbh->table_info(undef, undef, $table_name, 'TABLE');
    my $result = $sth->fetchall_arrayref;
    unless (@$result) {
        my $module_name = $self->load_module('SQL');
        if ($module_name && $module_name->can('has_table')) {
            $result = $module_name->has_table($self, $table_name);

        } 
    }
    $result;
}

=item set_session_variables

=cut

sub set_session_variables {
    my ($self, $db_session_variables) = @_;
    my $module_name = $self->load_module('SQL');
    if ($module_name && $module_name->can('set_session_variables')) {
        $module_name->set_session_variables($self, $db_session_variables);
    }
}


=item has_table

Returns true if table exists in database schema

=cut

sub has_table {
    my ($self, $table_name) = @_;
    my $result = $self->table_info($table_name);
    !! @$result;
}


=item has_sequence

Returns true if has sequence

=cut

sub has_sequence {
    my ($self, $sequence_name) = @_;    
    my $result;
    my $module_name = $self->load_module('SQL');
    if($module_name && $module_name->can('has_sequence')) {
        my $record = $self->record($module_name->has_sequence($self->username), $sequence_name);
        $result = $record->{sequence_name};    
    } else {
        warn "not implemented ${module_name}::has_sequence";
    }
    $result;
}


=item sequence_value

Returns sequence's value. Takes seqence name.

    $connection->sequence_value('emp_seq');

=cut

sub sequence_value {
    my ($self, $name) = @_;
    my $module_name = $self->load_module('SQL');
    my $sql = $module_name->sequence_value($name);
    my ($result) = $self->record($sql);
    $result->{val};
}


=item reset_sequence

Restart sequence. Takes sequence name, initial sequence value, incremental sequence value.

    $connection->reset_sequence('emp_seq', 1, 1);

=cut

sub reset_sequence {
    my ($self, $name, $start_with, $increment_by) = @_;
    $start_with ||= 1;
    $increment_by ||= 1;
    my $module_name = $self->load_module('SQL');
    if($module_name && $module_name->can('reset_sequence')) {
        my @sqls = $module_name->reset_sequence($name, $start_with, $increment_by, $self);
        $self->do($_) for @sqls;
    } else {
        warn "not implemented ${module_name}::reset_sequence";
    }
}


=item record_action_start_time

Records database operation start time.

=cut

sub record_action_start_time {
    my $self = shift;
    return unless $self->collect_statistics;
    $self->action_start_time([gettimeofday])
}


=item record_action_end_time

Records database operation end time.

=cut

sub record_action_end_time {
    my ($self, $name, $method)  = @_;
    return unless $self->collect_statistics;
    $method ||=  [split /::/, [caller(1)]->[3]]->[-1];
    my $duration = tv_interval($self->action_start_time, [gettimeofday]);
    my $tracking = $self->tracking;
    my $info = $tracking->{$name} ||= {};
    my $stats  = $info->{$method} ||= {};
    unless (exists($info->{" called"})) {
        $stats->{" called"} = 1;
        $stats->{min} = $duration;
        $stats->{max} = $duration;
        $stats->{avg} = $duration;
    } else {
        $stats->{" called"}++;
        $stats->{min} = $duration if $info->{min} > $duration;
        $stats->{max} = $duration if $info->{max} < $duration;
        $stats->{avg} = ($info->{avg} + $duration) / 2.0
    }
}


=item format_usage_report

Formats usage report.

=cut

sub format_usage_report {
    my $self = shift;
    return unless $self->collect_statistics;
    my $tracking = $self->tracking;
    my $footer = "";
    my $body = "";
    my $i = 0;
    foreach my $k (sort keys %$tracking) {
        $footer .= "$i: \n " . $k;
        $body .=  "SQL id $i:\n";
        
        my $item = $tracking->{$k};
        foreach my $j(sort keys %$item) {
            $body  .= "    $j => " ;
            my $details = $item->{$j};
            foreach my $m (sort keys %$details) {
                $body  .= " $m = " . $details->{$m}
            }
            $body .= "\n";
        }
        $body .= "\n";
        $i++;
    }
    return $self->name . " USAGE REPORT\n" . $body . "SQL:\n" . $footer;
}



=item print_usage_report

Prints usage report to stander output.

=cut

sub print_usage_report {
    my ($self, $fh) = @_;
    print $fh $self->format_usage_report;
}


=item print_usage_report_to_file

Prints usage report to file

=cut

sub print_usage_report_to_file {
    my ($self) = @_;
    my $dir = $self->statistics_dir;
    if($self->collect_statistics && -d $dir) {
        my $file = $dir . $self->name . "." . $$;
        open my $fh, '>>', $file
            or die "cant open file $file";
        $self->print_usage_report;
        ::close($fh);
    }
}

=item error_handler

Returns error message, takes error message, and optionally bind variables.
If bind variables are passed in the sql's place holders are replaced with the bind_variables.

=cut

sub error_handler {
    my ($self, $sql, $sql_handler) = @_;
    my $dbh = $self->dbh;
    my $message = "[" . $self->name ."]: " . $sql . '\': ' .($dbh ? $dbh->errstr : '');
    if ($self->custom_error_handler) {
        $self->custom_error_handler->($self, $message, $sql_handler);
    } else {
        confess $message;
    }
}


=item update_lob

Updates lob.

Takes table_name, lob column name, lob content, hash_ref to primary key values. optionally lob size column name.

    $connection->update_lob(lob_test => 'blob_content', $lob_content, {id => 1}, 'doc_size');

=cut

sub update_lob {
    my ($self, $table_name, $lob_column_name, $lob, $primary_key_values, $lob_size_column_name) = @_;
    my $module_name = $self->load_module('SQL');
    if($module_name && $module_name->can('update_lob')) {
        $module_name->update_lob($self, $table_name, $lob_column_name, $lob, $primary_key_values, $lob_size_column_name);
    } else {
        warn "not implemented ${module_name}::update_lob";
    }
}

=item fetch_lob

Returns lob, takes table name, lob column name, hash ref of primary key values, lob size column name

    my $lob = $connection->fetch_lob(lob_test => 'blob_content', {id => 1}, 'doc_size');

=cut

sub fetch_lob {
    my ($self, $table_name, $lob_column_name, $primary_key_values, $lob_size_column_name) = @_;
    my $result;
    my $module_name = $self->load_module('SQL');
    if($module_name && $module_name->can('fetch_lob')) {
        $result = $module_name->fetch_lob($self, $table_name, $lob_column_name, $primary_key_values, $lob_size_column_name);
    } else {
        warn "not implemented ${module_name}::fetch_lob";
    }
    $result;
}


=item _where_clause

Returns Where caluse sql fragment, takes hash ref of fields values.

=cut

sub _where_clause {
    my ($self, $field_values) = @_;
    " WHERE " .  join(" AND ", map {( $_ . ' = ? ')} sort keys %$field_values);
}


=item DESTORY

=cut

sub DESTORY {
    my ($self) = @_;
    $self->print_usage_report_to_file;
}


1;

__END__

=back

=head1 COPYRIGHT AND LICENSE

The DBIx::Connection module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<DBIx::QueryCursor>
L<DBIx::SQLHandler>
L<DBIx::PLSQLHandler>.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut
