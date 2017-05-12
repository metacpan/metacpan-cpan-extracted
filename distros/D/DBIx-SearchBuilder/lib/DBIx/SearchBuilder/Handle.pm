# $Header: /home/jesse/DBIx-SearchBuilder/history/SearchBuilder/Handle.pm,v 1.21 2002/01/28 06:11:37 jesse Exp $
package DBIx::SearchBuilder::Handle;

use strict;
use warnings;

use Carp qw(croak cluck);
use DBI;
use Class::ReturnValue;
use Encode qw();

use DBIx::SearchBuilder::Util qw/ sorted_values /;

use vars qw(@ISA %DBIHandle $PrevHandle $DEBUG %TRANSDEPTH %TRANSROLLBACK %FIELDS_IN_TABLE);


=head1 NAME

DBIx::SearchBuilder::Handle - Perl extension which is a generic DBI handle

=head1 SYNOPSIS

  use DBIx::SearchBuilder::Handle;

  my $handle = DBIx::SearchBuilder::Handle->new();
  $handle->Connect( Driver => 'mysql',
                    Database => 'dbname',
                    Host => 'hostname',
                    User => 'dbuser',
                    Password => 'dbpassword');
  # now $handle isa DBIx::SearchBuilder::Handle::mysql                    
 
=head1 DESCRIPTION

This class provides a wrapper for DBI handles that can also perform a number of additional functions.
 
=cut



=head2 new

Generic constructor

=cut

sub new  {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);

    @{$self->{'StatementLog'}} = ();
    return $self;
}



=head2 Connect PARAMHASH: Driver, Database, Host, User, Password

Takes a paramhash and connects to your DBI datasource. 

You should _always_ set

     DisconnectHandleOnDestroy => 1 

unless you have a legacy app like RT2 or RT 3.0.{0,1,2} that depends on the broken behaviour.

If you created the handle with 
     DBIx::SearchBuilder::Handle->new
and there is a DBIx::SearchBuilder::Handle::(Driver) subclass for the driver you have chosen,
the handle will be automatically "upgraded" into that subclass.

=cut

sub Connect  {
    my $self = shift;
    my %args = (
        Driver => undef,
        Database => undef,
        Host => undef,
        SID => undef,
        Port => undef,
        User => undef,
        Password => undef,
        RequireSSL => undef,
        DisconnectHandleOnDestroy => undef,
        @_
    );

    if ( $args{'Driver'} && !$self->isa( __PACKAGE__ .'::'. $args{'Driver'} ) ) {
        return $self->Connect( %args ) if $self->_UpgradeHandle( $args{'Driver'} );
    }

    # Setting this actually breaks old RT versions in subtle ways.
    # So we need to explicitly call it
    $self->{'DisconnectHandleOnDestroy'} = $args{'DisconnectHandleOnDestroy'};

    my $old_dsn = $self->DSN || '';
    my $new_dsn = $self->BuildDSN( %args );

    # Only connect if we're not connected to this source already
    return undef if $self->dbh && $self->dbh->ping && $new_dsn eq $old_dsn;

    my $handle = DBI->connect(
        $new_dsn, $args{'User'}, $args{'Password'}
    ) or croak "Connect Failed $DBI::errstr\n";

    # databases do case conversion on the name of columns returned.
    # actually, some databases just ignore case. this smashes it to something consistent
    $handle->{FetchHashKeyName} ='NAME_lc';

    # Set the handle
    $self->dbh($handle);

    return 1;
}


=head2 _UpgradeHandle DRIVER

This private internal method turns a plain DBIx::SearchBuilder::Handle into one
of the standard driver-specific subclasses.

=cut

sub _UpgradeHandle {
    my $self = shift;
    
    my $driver = shift;
    my $class = 'DBIx::SearchBuilder::Handle::' . $driver;
    local $@;
    eval "require $class";
    return if $@;

    bless $self, $class;
    return 1;
}


=head2 BuildDSN PARAMHASH

Takes a bunch of parameters:  

Required: Driver, Database,
Optional: Host, Port and RequireSSL

Builds a DSN suitable for a DBI connection

=cut

sub BuildDSN {
    my $self = shift;
    my %args = (
        Driver     => undef,
        Database   => undef,
        Host       => undef,
        Port       => undef,
        SID        => undef,
        RequireSSL => undef,
        @_
    );

    my $dsn = "dbi:$args{'Driver'}:dbname=$args{'Database'}";
    $dsn .= ";sid=$args{'SID'}"   if $args{'SID'};
    $dsn .= ";host=$args{'Host'}" if $args{'Host'};
    $dsn .= ";port=$args{'Port'}" if $args{'Port'};
    $dsn .= ";requiressl=1"       if $args{'RequireSSL'};

    return $self->{'dsn'} = $dsn;
}


=head2 DSN

Returns the DSN for this database connection.

=cut

sub DSN {
    return shift->{'dsn'};
}



=head2 RaiseError [MODE]

Turns on the Database Handle's RaiseError attribute.

=cut

sub RaiseError {
    my $self = shift;

    my $mode = 1; 
    $mode = shift if (@_);

    $self->dbh->{RaiseError}=$mode;
}




=head2 PrintError [MODE]

Turns on the Database Handle's PrintError attribute.

=cut

sub PrintError {
    my $self = shift;

    my $mode = 1; 
    $mode = shift if (@_);

    $self->dbh->{PrintError}=$mode;
}



=head2 LogSQLStatements BOOL

Takes a boolean argument. If the boolean is true, SearchBuilder will log all SQL
statements, as well as their invocation times and execution times.

Returns whether we're currently logging or not as a boolean

=cut

sub LogSQLStatements {
    my $self = shift;
    if (@_) {
        require Time::HiRes;
        $self->{'_DoLogSQL'} = shift;
    }
    return ($self->{'_DoLogSQL'});
}

=head2 _LogSQLStatement STATEMENT DURATION

Add an SQL statement to our query log

=cut

sub _LogSQLStatement {
    my $self = shift;
    my $statement = shift;
    my $duration = shift;
    my @bind = @_;
    push @{$self->{'StatementLog'}} , ([Time::HiRes::time(), $statement, [@bind], $duration, Carp::longmess("Executed SQL query")]);

}

=head2 ClearSQLStatementLog

Clears out the SQL statement log. 


=cut

sub ClearSQLStatementLog {
    my $self = shift;
    @{$self->{'StatementLog'}} = ();
}   


=head2 SQLStatementLog

Returns the current SQL statement log as an array of arrays. Each entry is a triple of 

(Time,  Statement, Duration)

=cut

sub SQLStatementLog {
    my $self = shift;
    return  (@{$self->{'StatementLog'}});

}



=head2 AutoCommit [MODE]

Turns on the Database Handle's AutoCommit attribute.

=cut

sub AutoCommit {
    my $self = shift;

    my $mode = 1; 
    $mode = shift if (@_);

    $self->dbh->{AutoCommit}=$mode;
}




=head2 Disconnect

Disconnect from your DBI datasource

=cut

sub Disconnect  {
    my $self = shift;
    my $dbh = $self->dbh;
    return unless $dbh;
    $self->Rollback(1);
    return $dbh->disconnect;
}



=head2 dbh [HANDLE]

Return the current DBI handle. If we're handed a parameter, make the database handle that.

=cut

# allow use of Handle as a synonym for DBH
*Handle=\&dbh;

sub dbh {
  my $self=shift;
  
  #If we are setting the database handle, set it.
  if ( @_ ) {
      $DBIHandle{$self} = $PrevHandle = shift;
      %FIELDS_IN_TABLE = ();
  }

  return($DBIHandle{$self} ||= $PrevHandle);
}


=head2 Insert $TABLE_NAME @KEY_VALUE_PAIRS

Takes a table name and a set of key-value pairs in an array.
Splits the key value pairs, constructs an INSERT statement
and performs the insert.

Base class return statement handle object, while DB specific
subclass should return row id.

=cut

sub Insert {
    my $self = shift;
    return $self->SimpleQuery( $self->InsertQueryString(@_) );
}

=head2 InsertQueryString $TABLE_NAME @KEY_VALUE_PAIRS

Takes a table name and a set of key-value pairs in an array.
Splits the key value pairs, constructs an INSERT statement
and returns query string and set of bind values.

This method is more useful for subclassing in DB specific
handles. L</Insert> method is preferred for end users.

=cut

sub InsertQueryString {
    my($self, $table, @pairs) = @_;
    my(@cols, @vals, @bind);

    while ( my $key = shift @pairs ) {
        push @cols, $key;
        push @vals, '?';
        push @bind, shift @pairs;
    }

    my $QueryString = "INSERT INTO $table";
    $QueryString .= " (". join(", ", @cols) .")";
    $QueryString .= " VALUES (". join(", ", @vals). ")";
    return ($QueryString, @bind);
}

=head2 InsertFromSelect

Takes table name, array reference with columns, select query
and list of bind values. Inserts data select by the query
into the table.

To make sure call is portable every column in result of
the query should have unique name or should be aliased.
See L<DBIx::SearchBuilder::Handle::Oracle/InsertFromSelect> for
details.

=cut

sub InsertFromSelect {
    my ($self, $table, $columns, $query, @binds) = @_;

    $columns = join ', ', @$columns
        if $columns;

    my $full_query = "INSERT INTO $table";
    $full_query .= " ($columns)" if $columns;
    $full_query .= ' '. $query;
    my $sth = $self->SimpleQuery( $full_query, @binds );
    return $sth unless $sth;

    my $rows = $sth->rows;
    return $rows == 0? '0E0' : $rows;
}

=head2 UpdateRecordValue 

Takes a hash with fields: Table, Column, Value PrimaryKeys, and 
IsSQLFunction.  Table, and Column should be obvious, Value is where you 
set the new value you want the column to have. The primary_keys field should 
be the lvalue of DBIx::SearchBuilder::Record::PrimaryKeys().  Finally 
IsSQLFunction is set when the Value is a SQL function.  For example, you 
might have ('Value'=>'PASSWORD(string)'), by setting IsSQLFunction that 
string will be inserted into the query directly rather then as a binding. 

=cut

sub UpdateRecordValue {
    my $self = shift;
    my %args = ( Table         => undef,
                 Column        => undef,
                 IsSQLFunction => undef,
                 PrimaryKeys   => undef,
                 @_ );

    my @bind  = ();
    my $query = 'UPDATE ' . $args{'Table'} . ' ';
     $query .= 'SET '    . $args{'Column'} . '=';

  ## Look and see if the field is being updated via a SQL function. 
  if ($args{'IsSQLFunction'}) {
     $query .= $args{'Value'} . ' ';
  }
  else {
     $query .= '? ';
     push (@bind, $args{'Value'});
  }

  ## Constructs the where clause.
  my $where  = 'WHERE ';
  foreach my $key (sort keys %{$args{'PrimaryKeys'}}) {
     $where .= $key . "=?" . " AND ";
     push (@bind, $args{'PrimaryKeys'}{$key});
  }
     $where =~ s/AND\s$//;
  
  my $query_str = $query . $where;
  return ($self->SimpleQuery($query_str, @bind));
}




=head2 UpdateTableValue TABLE COLUMN NEW_VALUE RECORD_ID IS_SQL

Update column COLUMN of table TABLE where the record id = RECORD_ID.  if IS_SQL is set,
don\'t quote the NEW_VALUE

=cut

sub UpdateTableValue  {
    my $self = shift;

    ## This is just a wrapper to UpdateRecordValue().     
    my %args = (); 
    $args{'Table'}  = shift;
    $args{'Column'} = shift;
    $args{'Value'}  = shift;
    $args{'PrimaryKeys'}   = shift; 
    $args{'IsSQLFunction'} = shift;

    return $self->UpdateRecordValue(%args)
}

=head1 SimpleUpdateFromSelect

Takes table name, hash reference with (column, value) pairs,
select query and list of bind values.

Updates the table, but only records with IDs returned by the
selected query, eg:

    UPDATE $table SET %values WHERE id IN ( $query )

It's simple as values are static and search only allowed
by id.

=cut

sub SimpleUpdateFromSelect {
    my ($self, $table, $values, $query, @query_binds) = @_;

    my @columns; my @binds;
    for my $k (sort keys %$values) {
        push @columns, $k;
        push @binds, $values->{$k};
    }

    my $full_query = "UPDATE $table SET ";
    $full_query .= join ', ', map "$_ = ?", @columns;
    $full_query .= ' WHERE id IN ('. $query .')';
    my $sth = $self->SimpleQuery( $full_query, @binds, @query_binds );
    return $sth unless $sth;

    my $rows = $sth->rows;
    return $rows == 0? '0E0' : $rows;
}

=head1 DeleteFromSelect

Takes table name, select query and list of bind values.

Deletes from the table, but only records with IDs returned by the
select query, eg:

    DELETE FROM $table WHERE id IN ($query)

=cut

sub DeleteFromSelect {
    my ($self, $table, $query, @binds) = @_;
    my $sth = $self->SimpleQuery(
        "DELETE FROM $table WHERE id IN ($query)",
        @binds
    );
    return $sth unless $sth;

    my $rows = $sth->rows;
    return $rows == 0? '0E0' : $rows;
}

=head2 SimpleQuery QUERY_STRING, [ BIND_VALUE, ... ]

Execute the SQL string specified in QUERY_STRING

=cut

sub SimpleQuery {
    my $self        = shift;
    my $QueryString = shift;
    my @bind_values;
    @bind_values = (@_) if (@_);

    my $sth = $self->dbh->prepare($QueryString);
    unless ($sth) {
        if ($DEBUG) {
            die "$self couldn't prepare the query '$QueryString'"
              . $self->dbh->errstr . "\n";
        }
        else {
            warn "$self couldn't prepare the query '$QueryString'"
              . $self->dbh->errstr . "\n";
            my $ret = Class::ReturnValue->new();
            $ret->as_error(
                errno   => '-1',
                message => "Couldn't prepare the query '$QueryString'."
                  . $self->dbh->errstr,
                do_backtrace => undef
            );
            return ( $ret->return_value );
        }
    }

    # Check @bind_values for HASH refs
    for ( my $bind_idx = 0 ; $bind_idx < scalar @bind_values ; $bind_idx++ ) {
        if ( ref( $bind_values[$bind_idx] ) eq "HASH" ) {
            my $bhash = $bind_values[$bind_idx];
            $bind_values[$bind_idx] = $bhash->{'value'};
            delete $bhash->{'value'};
            $sth->bind_param( $bind_idx + 1, undef, $bhash );
        }
    }

    my $basetime;
    if ( $self->LogSQLStatements ) {
        $basetime = Time::HiRes::time();
    }
    my $executed;
    {
        no warnings 'uninitialized' ; # undef in bind_values makes DBI sad
        eval { $executed = $sth->execute(@bind_values) };
    }
    if ( $self->LogSQLStatements ) {
        $self->_LogSQLStatement( $QueryString, Time::HiRes::time() - $basetime, @bind_values );
    }

    if ( $@ or !$executed ) {
        if ($DEBUG) {
            die "$self couldn't execute the query '$QueryString'"
              . $self->dbh->errstr . "\n";

        }
        else {
            cluck "$self couldn't execute the query '$QueryString'";

            my $ret = Class::ReturnValue->new();
            $ret->as_error(
                errno   => '-1',
                message => "Couldn't execute the query '$QueryString'"
                  . $self->dbh->errstr,
                do_backtrace => undef
            );
            return ( $ret->return_value );
        }

    }
    return ($sth);

}



=head2 FetchResult QUERY, [ BIND_VALUE, ... ]

Takes a SELECT query as a string, along with an array of BIND_VALUEs
If the select succeeds, returns the first row as an array.
Otherwise, returns a Class::ResturnValue object with the failure loaded
up.

=cut 

sub FetchResult {
  my $self = shift;
  my $query = shift;
  my @bind_values = @_;
  my $sth = $self->SimpleQuery($query, @bind_values);
  if ($sth) {
    return ($sth->fetchrow);
  }
  else {
   return($sth);
  }
}


=head2 BinarySafeBLOBs

Returns 1 if the current database supports BLOBs with embedded nulls.
Returns undef if the current database doesn't support BLOBs with embedded nulls

=cut

sub BinarySafeBLOBs {
    my $self = shift;
    return(1);
}



=head2 KnowsBLOBs

Returns 1 if the current database supports inserts of BLOBs automatically.
Returns undef if the current database must be informed of BLOBs for inserts.

=cut

sub KnowsBLOBs {
    my $self = shift;
    return(1);
}



=head2 BLOBParams FIELD_NAME FIELD_TYPE

Returns a hash ref for the bind_param call to identify BLOB types used by 
the current database for a particular column type.                 

=cut

sub BLOBParams {
    my $self = shift;
    # Don't assign to key 'value' as it is defined later. 
    return ( {} );
}



=head2 DatabaseVersion [Short => 1]

Returns the database's version.

If argument C<Short> is true returns short variant, in other
case returns whatever database handle/driver returns. By default
returns short version, e.g. '4.1.23' or '8.0-rc4'.

Returns empty string on error or if database couldn't return version.

The base implementation uses a C<SELECT VERSION()>

=cut

sub DatabaseVersion {
    my $self = shift;
    my %args = ( Short => 1, @_ );

    unless ( defined $self->{'database_version'} ) {

        # turn off error handling, store old values to restore later
        my $re = $self->RaiseError;
        $self->RaiseError(0);
        my $pe = $self->PrintError;
        $self->PrintError(0);

        my $statement = "SELECT VERSION()";
        my $sth       = $self->SimpleQuery($statement);

        my $ver = '';
        $ver = ( $sth->fetchrow_arrayref->[0] || '' ) if $sth;
        $ver =~ /(\d+(?:\.\d+)*(?:-[a-z0-9]+)?)/i;
        $self->{'database_version'}       = $ver;
        $self->{'database_version_short'} = $1 || $ver;

        $self->RaiseError($re);
        $self->PrintError($pe);
    }

    return $self->{'database_version_short'} if $args{'Short'};
    return $self->{'database_version'};
}

=head2 CaseSensitive

Returns 1 if the current database's searches are case sensitive by default
Returns undef otherwise

=cut

sub CaseSensitive {
    my $self = shift;
    return(1);
}





=head2 _MakeClauseCaseInsensitive FIELD OPERATOR VALUE

Takes a field, operator and value. performs the magic necessary to make
your database treat this clause as case insensitive.

Returns a FIELD OPERATOR VALUE triple.

=cut

our $RE_CASE_INSENSITIVE_CHARS = qr/[-'"\d: ]/;

sub _MakeClauseCaseInsensitive {
    my $self = shift;
    my $field = shift;
    my $operator = shift;
    my $value = shift;

    # don't downcase integer values and things that looks like dates
    if ($value !~ /^$RE_CASE_INSENSITIVE_CHARS+$/o) {
        $field = "lower($field)";
        $value = lc($value);
    }
    return ($field, $operator, $value,undef);
}

=head2 Transactions

L<DBIx::SearchBuilder::Handle> emulates nested transactions,
by keeping a transaction stack depth.

B<NOTE:> In nested transactions you shouldn't mix rollbacks and commits,
because only last action really do commit/rollback. For example next code
would produce desired results:

  $handle->BeginTransaction;
    $handle->BeginTransaction;
    ...
    $handle->Rollback;
    $handle->BeginTransaction;
    ...
    $handle->Commit;
  $handle->Commit;

Only last action(Commit in example) finilize transaction in DB.

=head3 BeginTransaction

Tells DBIx::SearchBuilder to begin a new SQL transaction.
This will temporarily suspend Autocommit mode.

=cut

sub BeginTransaction {
    my $self = shift;

    my $depth = $self->TransactionDepth;
    return unless defined $depth;

    $self->TransactionDepth(++$depth);
    return 1 if $depth > 1;

    return $self->dbh->begin_work;
}

=head3 EndTransaction [Action => 'commit'] [Force => 0]

Tells to end the current transaction. Takes C<Action> argument
that could be C<commit> or C<rollback>, the default value
is C<commit>.

If C<Force> argument is true then all nested transactions
would be committed or rolled back.

If there is no transaction in progress then method throw
warning unless action is forced.

Method returns true on success or false if error occured.

=cut

sub EndTransaction {
    my $self = shift;
    my %args = ( Action => 'commit', Force => 0, @_ );
    my $action = lc $args{'Action'} eq 'commit'? 'commit': 'rollback';

    my $depth = $self->TransactionDepth || 0;
    unless ( $depth ) {
        unless( $args{'Force'} ) {
            Carp::cluck( "Attempted to $action a transaction with none in progress" );
            return 0;
        }
        return 1;
    } else {
        $depth--;
    }
    $depth = 0 if $args{'Force'};

    $self->TransactionDepth( $depth );

    my $dbh = $self->dbh;
    $TRANSROLLBACK{ $dbh }{ $action }++;
    if ( $TRANSROLLBACK{ $dbh }{ $action eq 'commit'? 'rollback' : 'commit' } ) {
        warn "Rollback and commit are mixed while escaping nested transaction";
    }
    return 1 if $depth;

    delete $TRANSROLLBACK{ $dbh };

    if ($action eq 'commit') {
        return $dbh->commit;
    }
    else {
        DBIx::SearchBuilder::Record::Cachable->FlushCache
            if DBIx::SearchBuilder::Record::Cachable->can('FlushCache');
        return $dbh->rollback;
    }
}

=head3 Commit [FORCE]

Tells to commit the current SQL transaction.

Method uses C<EndTransaction> method, read its
L<description|DBIx::SearchBuilder::Handle/EndTransaction>.

=cut

sub Commit {
    my $self = shift;
    $self->EndTransaction( Action => 'commit', Force => shift );
}


=head3 Rollback [FORCE]

Tells to abort the current SQL transaction.

Method uses C<EndTransaction> method, read its
L<description|DBIx::SearchBuilder::Handle/EndTransaction>.

=cut

sub Rollback {
    my $self = shift;
    $self->EndTransaction( Action => 'rollback', Force => shift );
}


=head3 ForceRollback

Force the handle to rollback.
Whether or not we're deep in nested transactions.

=cut

sub ForceRollback {
    my $self = shift;
    $self->Rollback(1);
}


=head3 TransactionDepth

Returns the current depth of the nested transaction stack.
Returns C<undef> if there is no connection to database.

=cut

sub TransactionDepth {
    my $self = shift;

    my $dbh = $self->dbh;
    return undef unless $dbh && $dbh->ping;

    if ( @_ ) {
        my $depth = shift;
        if ( $depth ) {
            $TRANSDEPTH{ $dbh } = $depth;
        } else {
            delete $TRANSDEPTH{ $dbh };
        }
    }
    return $TRANSDEPTH{ $dbh } || 0;
}


=head2 ApplyLimits STATEMENTREF ROWS_PER_PAGE FIRST_ROW

takes an SQL SELECT statement and massages it to return ROWS_PER_PAGE starting with FIRST_ROW;

=cut

sub ApplyLimits {
    my $self = shift;
    my $statementref = shift;
    my $per_page = shift;
    my $first = shift;

    my $limit_clause = '';

    if ( $per_page) {
        $limit_clause = " LIMIT ";
        if ( $first ) {
            $limit_clause .= $first . ", ";
        }
        $limit_clause .= $per_page;
    }

   $$statementref .= $limit_clause; 

}





=head2 Join { Paramhash }

Takes a paramhash of everything Searchbuildler::Record does 
plus a parameter called 'SearchBuilder' that contains a ref 
to a SearchBuilder object'.

This performs the join.


=cut


sub Join {

    my $self = shift;
    my %args = (
        SearchBuilder => undef,
        TYPE          => 'normal',
        ALIAS1        => 'main',
        FIELD1        => undef,
        TABLE2        => undef,
        COLLECTION2   => undef,
        FIELD2        => undef,
        ALIAS2        => undef,
        EXPRESSION    => undef,
        @_
    );


    my $alias;

#If we're handed in an ALIAS2, we need to go remove it from the Aliases array.
# Basically, if anyone generates an alias and then tries to use it in a join later, we want to be smart about
# creating joins, so we need to go rip it out of the old aliases table and drop it in as an explicit join
    if ( $args{'ALIAS2'} ) {

        # this code is slow and wasteful, but it's clear.
        my @aliases = @{ $args{'SearchBuilder'}->{'aliases'} };
        my @new_aliases;
        foreach my $old_alias (@aliases) {
            if ( $old_alias =~ /^(.*?) (\Q$args{'ALIAS2'}\E)$/ ) {
                $args{'TABLE2'} = $1;
                $alias = $2;
            }
            else {
                push @new_aliases, $old_alias;
            }
        }

# If we found an alias, great. let's just pull out the table and alias for the other item
        unless ($alias) {

            # if we can't do that, can we reverse the join and have it work?
            my $a1 = $args{'ALIAS1'};
            my $f1 = $args{'FIELD1'};
            $args{'ALIAS1'} = $args{'ALIAS2'};
            $args{'FIELD1'} = $args{'FIELD2'};
            $args{'ALIAS2'} = $a1;
            $args{'FIELD2'} = $f1;

            @aliases     = @{ $args{'SearchBuilder'}->{'aliases'} };
            @new_aliases = ();
            foreach my $old_alias (@aliases) {
                if ( $old_alias =~ /^(.*?) ($args{'ALIAS2'})$/ ) {
                    $args{'TABLE2'} = $1;
                    $alias = $2;

                }
                else {
                    push @new_aliases, $old_alias;
                }
            }

        } else {
            # we found alias, so NewAlias should take care of distinctness
            $args{'DISTINCT'} = 1 unless exists $args{'DISTINCT'};
        }

        unless ( $alias ) {
            # XXX: this situation is really bug in the caller!!!
            return ( $self->_NormalJoin(%args) );
        }
        $args{'SearchBuilder'}->{'aliases'} = \@new_aliases;
    } elsif ( $args{'COLLECTION2'} ) {
        # We're joining to a pre-limited collection.  We need to take
        # all clauses in the other collection, munge 'main.' to a new
        # alias, apply them locally, then proceed as usual.
        my $collection = delete $args{'COLLECTION2'};
        $alias = $args{ALIAS2} = $args{'SearchBuilder'}->_GetAlias( $collection->Table );
        $args{TABLE2} = $collection->Table;

        eval {$collection->_ProcessRestrictions}; # RT hate

        # Move over unused aliases
        push @{$args{SearchBuilder}{aliases}}, @{$collection->{aliases}};

        # Move over joins, as well
        for my $join (sort keys %{$collection->{left_joins}}) {
            my %alias = %{$collection->{left_joins}{$join}};
            $alias{depends_on} = $alias if $alias{depends_on} eq "main";
            $alias{criteria} = $self->_RenameRestriction(
                RESTRICTIONS => $alias{criteria},
                NEW          => $alias
            );
            $args{SearchBuilder}{left_joins}{$join} = \%alias;
        }

        my $restrictions = $self->_RenameRestriction(
            RESTRICTIONS => $collection->{restrictions},
            NEW          => $alias
        );
        $args{SearchBuilder}{restrictions}{$_} = $restrictions->{$_} for keys %{$restrictions};
    } else {
        $alias = $args{'SearchBuilder'}->_GetAlias( $args{'TABLE2'} );
    }

    my $meta = $args{'SearchBuilder'}->{'left_joins'}{"$alias"} ||= {};
    if ( $args{'TYPE'} =~ /LEFT/i ) {
        $meta->{'alias_string'} = " LEFT JOIN " . $args{'TABLE2'} . " $alias ";
        $meta->{'type'} = 'LEFT';
    }
    else {
        $meta->{'alias_string'} = " JOIN " . $args{'TABLE2'} . " $alias ";
        $meta->{'type'} = 'NORMAL';
    }
    $meta->{'depends_on'} = $args{'ALIAS1'};

    my $criterion = $args{'EXPRESSION'} || $args{'ALIAS1'}.".".$args{'FIELD1'};
    $meta->{'criteria'}{'base_criterion'} =
        [ { field => "$alias.$args{'FIELD2'}", op => '=', value => $criterion } ];

    if ( $args{'DISTINCT'} && !defined $args{'SearchBuilder'}{'joins_are_distinct'} ) {
        $args{SearchBuilder}{joins_are_distinct} = 1;
    } elsif ( !$args{'DISTINCT'} ) {
        $args{SearchBuilder}{joins_are_distinct} = 0;
    }

    return ($alias);
}

sub _RenameRestriction {
    my $self = shift;
    my %args = (
        RESTRICTIONS => undef,
        OLD          => "main",
        NEW          => undef,
        @_,
    );

    my %return;
    for my $key ( keys %{$args{RESTRICTIONS}} ) {
        my $newkey = $key;
        $newkey =~ s/^\Q$args{OLD}\E\./$args{NEW}./;
        my @parts;
        for my $part ( @{ $args{RESTRICTIONS}{$key} } ) {
            if ( ref $part ) {
                my %part = %{$part};
                $part{field} =~ s/^\Q$args{OLD}\E\./$args{NEW}./;
                $part{value} =~ s/^\Q$args{OLD}\E\./$args{NEW}./;
                push @parts, \%part;
            } else {
                push @parts, $part;
            }
        }
        $return{$newkey} = \@parts;
    }
    return \%return;
}

sub _NormalJoin {

    my $self = shift;
    my %args = (
        SearchBuilder => undef,
        TYPE          => 'normal',
        FIELD1        => undef,
        ALIAS1        => undef,
        TABLE2        => undef,
        FIELD2        => undef,
        ALIAS2        => undef,
        @_
    );

    my $sb = $args{'SearchBuilder'};

    if ( $args{'TYPE'} =~ /LEFT/i ) {
        my $alias = $sb->_GetAlias( $args{'TABLE2'} );
        my $meta = $sb->{'left_joins'}{"$alias"} ||= {};
        $meta->{'alias_string'} = " LEFT JOIN $args{'TABLE2'} $alias ";
        $meta->{'depends_on'}   = $args{'ALIAS1'};
        $meta->{'type'}         = 'LEFT';
        $meta->{'criteria'}{'base_criterion'} = [ {
            field => "$args{'ALIAS1'}.$args{'FIELD1'}",
            op => '=',
            value => "$alias.$args{'FIELD2'}",
        } ];

        return ($alias);
    }
    else {
        $sb->DBIx::SearchBuilder::Limit(
            ENTRYAGGREGATOR => 'AND',
            QUOTEVALUE      => 0,
            ALIAS           => $args{'ALIAS1'},
            FIELD           => $args{'FIELD1'},
            VALUE           => $args{'ALIAS2'} . "." . $args{'FIELD2'},
            @_
        );
    }
}

# this code is all hacky and evil. but people desperately want _something_ and I'm 
# super tired. refactoring gratefully appreciated.

sub _BuildJoins {
    my $self = shift;
    my $sb   = shift;

    $self->OptimizeJoins( SearchBuilder => $sb );

    my $join_clause = join " CROSS JOIN ", ($sb->Table ." main"), @{ $sb->{'aliases'} };
    my %processed = map { /^\S+\s+(\S+)$/; $1 => 1 } @{ $sb->{'aliases'} };
    $processed{'main'} = 1;

    # get a @list of joins that have not been processed yet, but depend on processed join
    my $joins = $sb->{'left_joins'};
    while ( my @list =
        grep !$processed{ $_ }
            && (!$joins->{ $_ }{'depends_on'} || $processed{ $joins->{ $_ }{'depends_on'} }),
        sort keys %$joins
    ) {
        foreach my $join ( @list ) {
            $processed{ $join }++;

            my $meta = $joins->{ $join };
            my $aggregator = $meta->{'entry_aggregator'} || 'AND';

            $join_clause .= $meta->{'alias_string'} . " ON ";
            my @tmp = map {
                    ref($_)?
                        $_->{'field'} .' '. $_->{'op'} .' '. $_->{'value'}:
                        $_
                }
                map { ('(', @$_, ')', $aggregator) } sorted_values($meta->{'criteria'});
            pop @tmp;
            $join_clause .= join ' ', @tmp;
        }
    }

    # here we could check if there is recursion in joins by checking that all joins
    # are processed
    if ( my @not_processed = grep !$processed{ $_ }, keys %$joins ) {
        die "Unsatisfied dependency chain in joins @not_processed";
    }
    return $join_clause;
}

sub OptimizeJoins {
    my $self = shift;
    my %args = (SearchBuilder => undef, @_);
    my $joins = $args{'SearchBuilder'}->{'left_joins'};

    my %processed = map { /^\S+\s+(\S+)$/; $1 => 1 } @{ $args{'SearchBuilder'}->{'aliases'} };
    $processed{ $_ }++ foreach grep $joins->{ $_ }{'type'} ne 'LEFT', keys %$joins;
    $processed{'main'}++;

    my @ordered;
    # get a @list of joins that have not been processed yet, but depend on processed join
    # if we are talking about forest then we'll get the second level of the forest,
    # but we should process nodes on this level at the end, so we build FILO ordered list.
    # finally we'll get ordered list with leafes in the beginning and top most nodes at
    # the end.
    while ( my @list = grep !$processed{ $_ }
            && $processed{ $joins->{ $_ }{'depends_on'} }, sort keys %$joins )
    {
        unshift @ordered, @list;
        $processed{ $_ }++ foreach @list;
    }

    foreach my $join ( @ordered ) {
        next if $self->MayBeNull( SearchBuilder => $args{'SearchBuilder'}, ALIAS => $join );

        $joins->{ $join }{'alias_string'} =~ s/^\s*LEFT\s+/ /;
        $joins->{ $join }{'type'} = 'NORMAL';
    }

    # here we could check if there is recursion in joins by checking that all joins
    # are processed

}

=head2 MayBeNull

Takes a C<SearchBuilder> and C<ALIAS> in a hash and resturns
true if restrictions of the query allow NULLs in a table joined with
the ALIAS, otherwise returns false value which means that you can
use normal join instead of left for the aliased table.

Works only for queries have been built with L<DBIx::SearchBuilder/Join> and
L<DBIx::SearchBuilder/Limit> methods, for other cases return true value to
avoid fault optimizations.

=cut

sub MayBeNull {
    my $self = shift;
    my %args = (SearchBuilder => undef, ALIAS => undef, @_);
    # if we have at least one subclause that is not generic then we should get out
    # of here as we can't parse subclauses
    return 1 if grep $_ ne 'generic_restrictions', keys %{ $args{'SearchBuilder'}->{'subclauses'} };

    # build full list of generic conditions
    my @conditions;
    foreach ( grep @$_, sorted_values($args{'SearchBuilder'}->{'restrictions'}) ) {
        push @conditions, 'AND' if @conditions;
        push @conditions, '(', @$_, ')';
    }

    # find tables that depends on this alias and add their join conditions
    foreach my $join ( sorted_values($args{'SearchBuilder'}->{'left_joins'}) ) {
        # left joins on the left side so later we'll get 1 AND x expression
        # which equal to x, so we just skip it
        next if $join->{'type'} eq 'LEFT';
        next unless $join->{'depends_on'} eq $args{'ALIAS'};

        my @tmp = map { ('(', @$_, ')', $join->{'entry_aggregator'}) } sorted_values($join->{'criteria'});
        pop @tmp;

        @conditions = ('(', @conditions, ')', 'AND', '(', @tmp ,')');

    }
    return 1 unless @conditions;

    # replace conditions with boolean result: 1 - allows nulls, 0 - not
    # all restrictions on that don't act on required alias allow nulls
    # otherwise only IS NULL operator 
    foreach ( splice @conditions ) {
        unless ( ref $_ ) {
            push @conditions, $_;
        } elsif ( rindex( $_->{'field'}, "$args{'ALIAS'}.", 0 ) == 0 ) {
            # field is alias.xxx op ... and only IS op allows NULLs
            push @conditions, lc $_->{op} eq 'is';
        } elsif ( $_->{'value'} && rindex( $_->{'value'}, "$args{'ALIAS'}.", 0 ) == 0 ) {
            # value is alias.xxx so it can not be IS op
            push @conditions, 0;
        } elsif ( $_->{'field'} =~ /^(?i:lower)\(\s*\Q$args{'ALIAS'}\./ ) {
            # handle 'LOWER(alias.xxx) OP VALUE' we use for case insensetive
            push @conditions, lc $_->{op} eq 'is';
        } else {
            push @conditions, 1;
        }
    }

    # resturns index of closing paren by index of openning paren
    my $closing_paren = sub {
        my $i = shift;
        my $count = 0;
        for ( ; $i < @conditions; $i++ ) {
            if ( $conditions[$i] eq '(' ) {
                $count++;
            }
            elsif ( $conditions[$i] eq ')' ) {
                $count--;
            }
            return $i unless $count;
        }
        die "lost in parens";
    };

    # solve boolean expression we have, an answer is our result
    my $parens_count = 0;
    my @tmp = ();
    while ( defined ( my $e = shift @conditions ) ) {
        #print "@tmp >>>$e<<< @conditions\n";
        return $e if !@conditions && !@tmp;

        unless ( $e ) {
            if ( $conditions[0] eq ')' ) {
                push @tmp, $e;
                next;
            }

            my $aggreg = uc shift @conditions;
            if ( $aggreg eq 'OR' ) {
                # 0 OR x == x
                next;
            } elsif ( $aggreg eq 'AND' ) {
                # 0 AND x == 0
                my $close_p = $closing_paren->(0);
                splice @conditions, 0, $close_p + 1, (0);
            } else {
                die "unknown aggregator: @tmp $e >>>$aggreg<<< @conditions";
            }
        } elsif ( $e eq '1' ) {
            if ( $conditions[0] eq ')' ) {
                push @tmp, $e;
                next;
            }

            my $aggreg = uc shift @conditions;
            if ( $aggreg eq 'OR' ) {
                # 1 OR x == 1
                my $close_p = $closing_paren->(0);
                splice @conditions, 0, $close_p + 1, (1);
            } elsif ( $aggreg eq 'AND' ) {
                # 1 AND x == x
                next;
            } else {
                die "unknown aggregator: @tmp $e >>>$aggreg<<< @conditions";
            }
        } elsif ( $e eq '(' ) {
            if ( $conditions[1] eq ')' ) {
                splice @conditions, 1, 1;
            } else {
                $parens_count++;
                push @tmp, $e;
            }
        } elsif ( $e eq ')' ) {
            die "extra closing paren: @tmp >>>$e<<< @conditions"
                if --$parens_count < 0;

            unshift @conditions, @tmp, $e;
            @tmp = ();
        } else {
            die "lost: @tmp >>>$e<<< @conditions";
        }
    }
    return 1;
}

=head2 DistinctQuery STATEMENTREF 

takes an incomplete SQL SELECT statement and massages it to return a DISTINCT result set.


=cut

sub DistinctQuery {
    my $self = shift;
    my $statementref = shift;
    my $sb = shift;

    my $QueryHint = $sb->QueryHint;
    $QueryHint = $QueryHint ? " /* $QueryHint */ " : " ";

    # Prepend select query for DBs which allow DISTINCT on all column types.
    $$statementref = "SELECT" . $QueryHint . "DISTINCT main.* FROM $$statementref";
    $$statementref .= $sb->_GroupClause;
    $$statementref .= $sb->_OrderClause;
}




=head2 DistinctCount STATEMENTREF 

takes an incomplete SQL SELECT statement and massages it to return a DISTINCT result set.


=cut

sub DistinctCount {
    my $self = shift;
    my $statementref = shift;
    my $sb = shift;

    my $QueryHint = $sb->QueryHint;
    $QueryHint = $QueryHint ? " /* $QueryHint */ " : " ";

    # Prepend select query for DBs which allow DISTINCT on all column types.
    $$statementref = "SELECT" . $QueryHint . "COUNT(DISTINCT main.id) FROM $$statementref";

}

sub Fields {
    my $self  = shift;
    my $table = lc shift;

    unless ( $FIELDS_IN_TABLE{$table} ) {
        $FIELDS_IN_TABLE{ $table } = [];
        my $sth = $self->dbh->column_info( undef, '', $table, '%' )
            or return ();
        my $info = $sth->fetchall_arrayref({});
        foreach my $e ( @$info ) {
            push @{ $FIELDS_IN_TABLE{ $table } }, $e->{'COLUMN_NAME'};
        }
    }

    return @{ $FIELDS_IN_TABLE{ $table } };
}


=head2 Log MESSAGE

Takes a single argument, a message to log.

Currently prints that message to STDERR

=cut

sub Log {
	my $self = shift;
	my $msg = shift;
	warn $msg."\n";

}

=head2 SimpleDateTimeFunctions

See L</DateTimeFunction> for details on supported functions.
This method is for implementers of custom DB connectors.

Returns hash reference with (function name, sql template) pairs.

=cut

sub SimpleDateTimeFunctions {
    my $self = shift;
    return {
        datetime       => 'SUBSTR(?, 1,  19)',
        time           => 'SUBSTR(?, 12,  8)',

        hourly         => 'SUBSTR(?, 1,  13)',
        hour           => 'SUBSTR(?, 12, 2 )',

        date           => 'SUBSTR(?, 1,  10)',
        daily          => 'SUBSTR(?, 1,  10)',

        day            => 'SUBSTR(?, 9,  2 )',
        dayofmonth     => 'SUBSTR(?, 9,  2 )',

        monthly        => 'SUBSTR(?, 1,  7 )',
        month          => 'SUBSTR(?, 6,  2 )',

        annually       => 'SUBSTR(?, 1,  4 )',
        year           => 'SUBSTR(?, 1,  4 )',
    };
}

=head2 DateTimeFunction

Takes named arguments:

=over 4

=item * Field - SQL expression date/time function should be applied
to. Note that this argument is used as is without any kind of quoting.

=item * Type - name of the function, see supported values below.

=item * Timezone - optional hash reference with From and To values,
see L</ConvertTimezoneFunction> for details.

=back

Returns SQL statement. Returns NULL if function is not supported.

=head3 Supported functions

Type value in L</DateTimeFunction> is case insesitive. Spaces,
underscores and dashes are ignored. So 'date time', 'DateTime'
and 'date_time' are all synonyms. The following functions are
supported:

=over 4

=item * date time - as is, no conversion, except applying timezone
conversion if it's provided.

=item * time - time only

=item * hourly - datetime prefix up to the hours, e.g. '2010-03-25 16'

=item * hour - hour, 0 - 23

=item * date - date only

=item * daily - synonym for date

=item * day of week - 0 - 6, 0 - Sunday

=item * day - day of month, 1 - 31

=item * day of month - synonym for day

=item * day of year - 1 - 366, support is database dependent

=item * month - 1 - 12

=item * monthly - year and month prefix, e.g. '2010-11'

=item * year - e.g. '2023'

=item * annually - synonym for year

=item * week of year - 0-53, presence of zero week, 1st week meaning
and whether week starts on Monday or Sunday heavily depends on database.

=back

=cut

sub DateTimeFunction {
    my $self = shift;
    my %args = (
        Field => undef,
        Type => '',
        Timezone => undef,
        @_
    );

    my $res = $args{'Field'} || '?';
    if ( $args{'Timezone'} ) {
        $res = $self->ConvertTimezoneFunction(
            %{ $args{'Timezone'} },
            Field => $res,
        );
    }

    my $norm_type = lc $args{'Type'};
    $norm_type =~ s/[ _-]//g;
    if ( my $template = $self->SimpleDateTimeFunctions->{ $norm_type } ) {
        $template =~ s/\?/$res/;
        $res = $template;
    }
    else {
        return 'NULL';
    }
    return $res;
}

=head2 ConvertTimezoneFunction

Generates a function applied to Field argument that converts timezone.
By default converts from UTC. Examples:

    # UTC => Moscow
    $handle->ConvertTimezoneFunction( Field => '?', To => 'Europe/Moscow');

If there is problem with arguments or timezones are equal
then Field returned without any function applied. Field argument
is not escaped in any way, it's your job.

Implementation is very database specific. To be portable convert
from UTC or to UTC. Some databases have internal storage for
information about timezones that should be kept up to date.
Read documentation for your DB.

=cut

sub ConvertTimezoneFunction {
    my $self = shift;
    my %args = (
        From  => 'UTC',
        To    => undef,
        Field => '',
        @_
    );
    return $args{'Field'};
}

=head2 DateTimeIntervalFunction

Generates a function to calculate interval in seconds between two
dates. Takes From and To arguments which can be either scalar or
a hash. Hash is processed with L<DBIx::SearchBuilder/CombineFunctionWithField>.

Arguments are not quoted or escaped in any way. It's caller's job.

=cut

sub DateTimeIntervalFunction {
    my $self = shift;
    my %args = ( From => undef, To => undef, @_ );

    $_ = DBIx::SearchBuilder->CombineFunctionWithField(%$_)
        for grep ref, @args{'From', 'To'};

    return $self->_DateTimeIntervalFunction( %args );
}

sub _DateTimeIntervalFunction { return 'NULL' }

=head2 NullsOrder

Sets order of NULLs when sorting columns when called with mode,
but only if DB supports it. Modes:

=over 4

=item * small

NULLs are smaller then anything else, so come first when order
is ASC and last otherwise.

=item * large

NULLs are larger then anything else.

=item * first

NULLs are always first.

=item * last

NULLs are always last.

=item * default

Return back to DB's default behaviour.

=back

When called without argument returns metadata required to generate
SQL.

=cut

sub NullsOrder {
    my $self = shift;

    unless ($self->HasSupportForNullsOrder) {
        warn "No support for changing NULLs order" if @_;
        return undef;
    }

    if ( @_ ) {
        my $mode = shift || 'default';
        if ( $mode eq 'default' ) {
            delete $self->{'nulls_order'};
        }
        elsif ( $mode eq 'small' ) {
            $self->{'nulls_order'} = { ASC => 'NULLS FIRST', DESC => 'NULLS LAST' };
        }
        elsif ( $mode eq 'large' ) {
            $self->{'nulls_order'} = { ASC => 'NULLS LAST', DESC => 'NULLS FIRST' };
        }
        elsif ( $mode eq 'first' ) {
            $self->{'nulls_order'} = { ASC => 'NULLS FIRST', DESC => 'NULLS FIRST' };
        }
        elsif ( $mode eq 'last' ) {
            $self->{'nulls_order'} = { ASC => 'NULLS LAST', DESC => 'NULLS LAST' };
        }
        else {
            warn "'$mode' is not supported NULLs ordering mode";
            delete $self->{'nulls_order'};
        }
    }

    return undef unless $self->{'nulls_order'};
    return $self->{'nulls_order'};
}

=head2 HasSupportForNullsOrder

Returns true value if DB supports adjusting NULLs order while sorting
a column, for example C<ORDER BY Value ASC NULLS FIRST>.

=cut

sub HasSupportForNullsOrder {
    return 0;
}


=head2 DESTROY

When we get rid of the Searchbuilder::Handle, we need to disconnect from the database

=cut

sub DESTROY {
  my $self = shift;
  $self->Disconnect if $self->{'DisconnectHandleOnDestroy'};
  delete $DBIHandle{$self};
}


1;
__END__


=head1 AUTHOR

Jesse Vincent, jesse@fsck.com

=head1 SEE ALSO

perl(1), L<DBIx::SearchBuilder>

=cut

