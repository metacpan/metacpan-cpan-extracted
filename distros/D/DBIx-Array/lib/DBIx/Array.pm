package DBIx::Array;
use strict;
use warnings;
use File::Basename qw{basename};
use Tie::Cache;
use Data::Dumper qw{Dumper};
use List::Util qw(sum);
use DBI;
use DBIx::Array::Session::Action;

our $VERSION = '0.65';
our $PACKAGE = __PACKAGE__;

=head1 NAME

DBIx::Array - DBI Wrapper with Perl style data structure interfaces

=head1 SYNOPSIS

  use DBIx::Array;
  my $dbx   = DBIx::Array->new;
  $dbx->connect($connection, $user, $pass, \%opt); #passed to DBI
  my @array = $dbx->sqlarray($sql, @params);

With a connected database handle

  use DBIx::Array;
  my $dbx   = DBIx::Array->new(dbh=>$dbh);

With stored connection information from a File

  use DBIx::Array::Connect;
  my $dbx   = DBIx::Array::Connect->new(file=>"my.ini")->connect("mydatabase");

=head1 DESCRIPTION

This module provides a Perl data structure interface for Structured Query Language (SQL).  This module is for people who truly understand SQL and who understand Perl data structures.  If you understand how to modify your SQL to meet your data requirements then this module is for you.

This module is used to connect to Oracle 10g and 11g using L<DBD::Oracle> on both Linux and Win32, MySQL 4 and 5 using L<DBD::mysql> on Linux, Microsoft SQL Server using L<DBD::Sybase> on Linux and using L<DBD::ODBC> on Win32 systems, and PostgreSQL using L<DBD::Pg> in a 24x7 production environment.  Tests are written against L<DBD::CSV> and L<DBD::XBase>.

=head2 CONVENTIONS

=over

=item Methods are named "type + data structure".

=over

=item sql - Methods that are type "sql" use the passed SQL to hit the database.

=item abs - Methods that are type "abs" use L<SQL::Abstract> to build the SQL to hit the database.

=item sqlwhere - Methods that are type "sqlwhere" use the passed SQL appended with the passed where structure with L<SQL::Abstract>->where to build the SQL to hit the database.

=back

=item Methods data structures are:

=over

=item scalar - which is a single value the value from the first column of the first row.

=item array - which is a flattened list of values from all columns from all rows.

=item hash - which is the first two columns of values as a hash or hash reference

=item arrayarray - which is an array of array references (i.e. data table)

=item arrayhash - which is an array of hash references (works best when used with case sensitive column aliases)

=item hashhash - which is a hash where the keys are the values of the first column and the values are a hash reference of all (including the key) column values.

=item arrayarrayname - which is an array of array references (i.e. data table) with the first row being the column names passed from the database

=item arrayhashname - which is an array of hash references with the first row being the column names passed from the database

=item arrayobject - which is an array of hash references blessed into the passed class namespace

=back

=item Methods are context sensitive

=over

=item Methods in list context return a list e.g. (), ([],[],[],...), ({},{},{},...)

=item Methods in scalar context return an array reference e.g. [], [[],[],[],...], [{},{},{},...]

=back

=back

=head1 USAGE

Loop through data

  foreach my $row ($dbx->sqlarrayhash($sql, @bind)) {
    do_something($row->{"id"}, $row->{"column"});
  }

Easily generate an HTML table

  my $cgi  = CGI->new("");
  my $html = $cgi->table($cgi->Tr([map {$cgi->td($_)} $dbx->sqlarrayarrayname($sql, @param)]));

Bless directly into a class

  my ($object) = $dbx->sqlarrayobject("My::Package", $sql, {id=>$id}); #bless({id=>1, name=>'foo'}, 'My::Package');
  my @objects  = $dbx->absarrayobject("My::Package", "myview", '*', {active=>1}, ["name"]); #($object, $object, ...)

=head1 CONSTRUCTOR

=head2 new

  my $dbx = DBIx::Array->new();
  $dbx->connect(...); #connect to database, sets and returns dbh

  my $dbx = DBIx::Array->new(dbh=>$dbh); #already have a handle

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head2 initialize

=cut

sub initialize {
  my $self = shift;
  %$self   = @_;
}

=head1 METHODS (Properties)

=head2 dbh

Sets or returns the database handle object.

  my $dbh = $dbx->dbh;
  $dbx->dbh($dbh);  #if you already have a connection

=cut

sub dbh {
  my $self = shift;
  if (@_) {
    CORE::delete $self->{'_prepared'}; #clear cache if we switch handles
    $self->{'dbh'} = shift;
  }
  return $self->{'dbh'};
}

=head2 name

Sets or returns a user friendly identification string for this database connection

  my $name = $dbx->name;
  $dbx->name($string);

=cut

sub name {
  my $self        = shift;
  $self->{'name'} = shift if @_;
  return $self->{'name'};
}

=head1 METHODS (DBI Wrappers)

=head2 connect

Wrapper around DBI->connect; Connects to the database, sets dbh property, and returns the database handle.

  $dbx->connect($connection, $user, $pass, \%opt); #sets $dbx->dbh
  my $dbh = $dbx->connect($connection, $user, $pass, \%opt);

Examples:

  $dbx->connect("DBI:mysql:database=mydb;host=myhost", "user", "pass", {AutoCommit=>1, RaiseError=>1});
  $dbx->connect("DBI:Sybase:server=myhost;datasbase=mydb", "user", "pass", {AutoCommit=>1, RaiseError=>1}); #Microsoft SQL Server API is same as Sybase API
  $dbx->connect("DBI:Oracle:TNSNAME", "user", "pass", {AutoCommit=>1, RaiseError=>1});

=cut

sub connect {
  my $self = shift;
  local $0 = sprintf("perl:%s", basename($0)); #Force DBD::Oracle to show "perl:script@host" in v$session.program instead of "perl@host"
  my $dbh  = DBI->connect(@_);
  $self->dbh($dbh);
  CORE::delete $self->{'action'} if exists $self->{'action'};
  tie $self->{'action'}, "DBIx::Array::Session::Action", (parent=>$self);
  return $self->dbh;
}

=head2 disconnect

Wrapper around dbh->disconnect

  $dbx->disconnect;

=cut

sub disconnect {
  my $self = shift;
  untie $self->{'action'};
  CORE::delete $self->{'action'};
  return $self->dbh->disconnect
}

=head2 commit

Wrapper around dbh->commit

  $dbx->commit;

=cut

sub commit {
  my $self = shift;
  local $self->dbh->{'AutoCommit'} = 0;
  return $self->dbh->commit;
}

=head2 rollback

Wrapper around dbh->rollback

  $dbx->rollback;

=cut

sub rollback {
  my $self = shift;
  return $self->dbh->rollback;
}

=head2 prepare

Wrapper around dbh->prepare with a L<Tie::Cache> cache.

  my $sth = $dbx->prepare($sql);

=cut

sub prepare {
  my $self  = shift;
  my $sql   = shift;
  my $sth;
  if ($self->prepare_max_count > 0) {
    my $cache = $self->{'_prepared'} ||= $self->_prepare_tie;       #orisahash
    $sth      = $cache->{$sql}       ||= $self->dbh->prepare($sql); #orisacache
  } else {
    $sth      = $self->dbh->prepare($sql);
  }
  die($self->errstr) unless $sth;
  return $sth;
}

sub _prepare_tie {
  my $self = shift;
  my $hash = {};
  tie %$hash, 'Tie::Cache', {MaxCount => $self->prepare_max_count};
  return $hash;
}

=head2 prepare_max_count

Maximum number of prepared statements to keep in the cache.

  $dbx->prepare_max_count(128); #default
  $dbx->prepare_max_count(0);   #disabled

=cut

sub prepare_max_count {
  my $self = shift;
  if (@_) {
    $self->{"prepare_max_count"} = shift;
    CORE::delete $self->{'_prepared'}; #clear cache if we switch handles
  }
  $self->{"prepare_max_count"} = 128 unless defined $self->{"prepare_max_count"};
  return $self->{"prepare_max_count"};
}

=head2 AutoCommit

Wrapper around dbh->{'AutoCommit'}

  $dbx->AutoCommit(1);
  &doSomething if $dbx->AutoCommit;

For transactions that must complete together, I recommend

  { #block to keep local... well... local.
    local $dbx->dbh->{'AutoCommit'} = 0;
    $dbx->sqlinsert($sql1, @bind1);
    $dbx->sqlupdate($sql2, @bind2);
    $dbx->sqlinsert($sql3, @bind3);
  } #What is AutoCommit now?  Do you care?

If AutoCommit reverts to true at the end of the block then DBI commits.  Else AutoCommit is still false and still not committed.  This allows higher layers to determine commit functionality.

=cut

sub AutoCommit {
  my $self = shift;
  if (@_) {
    $self->dbh->{'AutoCommit'} = shift;
  }
  return $self->dbh->{'AutoCommit'};
}

=head2 RaiseError

Wrapper around dbh->{'RaiseError'}

  $dbx->RaiseError(1);
  &doSomething if $dbx->RaiseError;

  { #local block
    local $dbx->dbh->{'RaiseError'} = 0;
    $dbx->sqlinsert($sql, @bind); #do not die
  }

=cut

sub RaiseError {
  my $self = shift;
  if (@_) {
    $self->dbh->{'RaiseError'} = shift;
  }
  return $self->dbh->{'RaiseError'};
}

=head2 errstr

Wrapper around $DBI::errstr

  my $err = $dbx->errstr;

=cut

sub errstr {$DBI::errstr};

=head1 METHODS (Read) - SQL

=head2 sqlcursor

Returns the prepared and executed SQL cursor so that you can use the cursor elsewhere.  Every method in this package uses this single method to generate a sqlcursor.

  my $sth = $dbx->sqlcursor($sql,  @param); #binds are ? values are positional
  my $sth = $dbx->sqlcursor($sql, \@param); #binds are ? values are positional
  my $sth = $dbx->sqlcursor($sql, \%param); #binds are :key

Note: In true Perl fashion extra hash binds are ignored.

  my @foo = $dbx->sqlarray("select :foo, :bar from dual",
                           {foo=>"a", bar=>1, baz=>"buz"}); #returns ("a", 1)

  my $one = $dbx->sqlscalar("select ? from dual", ["one"]); #returns "one"

  my $two = $dbx->sqlscalar("select ? from dual", "two");   #returns "two"

Scalar references are passed in and out with a hash bind.

  my $inout = 3;
  $dbx->sqlexecute("BEGIN :inout := :inout * 2; END;", {inout=>\$inout});
  print "$inout\n";  #$inout is 6

Direct Plug-in for L<SQL::Abstract> but no column alias support.

  my $sabs = SQL::Abstract->new;
  my $sth  = $dbx->sqlcursor($sabs->select($table, \@columns, \%where, \@sort));

=cut

sub sqlcursor {
  my $self = shift;
  my $sql  = shift;
  my $sth  = $self->prepare($sql);
  if (ref($_[0]) eq "ARRAY") {
    my $bind_aref = shift;
    $sth->execute(@$bind_aref) or die(&_error_string($self->errstr, $sql, sprintf("[%s]", join(", ", @$bind_aref)), "Array Reference"));
  } elsif (ref($_[0]) eq "HASH") {
    my $bind_href = shift;
    foreach my $key (keys %$bind_href) {
      next unless $sql =~ m/:$key\b/;                #TODO: comments are scanned so /* :foo */ is not supported here
      if (ref($bind_href->{$key}) eq "SCALAR") {
        $sth->bind_param_inout(":$key" => $bind_href->{$key}, 255);
      } else {
        $sth->bind_param(":$key" => $bind_href->{$key});
      }
    }
    $sth->execute or die(&_error_string($self->errstr, $sql, sprintf("{%s}", join(", ", map {join("=>", $_ => $bind_href->{$_})} sort keys %$bind_href)), "Hash Reference"));
  } else {
    my @bind = @_;
    $sth->execute(@bind) or die(&_error_string($self->errstr, $sql, sprintf("(%s)", join(", ", @bind)), "List"));
  }
  return $sth;

  sub _error_string {
    my $err      = shift;
    my $sql      = shift;
    my $bind_str = shift;
    my $type     = shift;
    if ($bind_str) {
      return sprintf("Database Execute Error: %s\nSQL: %s\nBind(%s): %s\n", $err, $sql, $type, $bind_str);
    } else {
      return sprintf("Database Prepare Error: %s\nSQL: %s\n", $err, $sql);
    }
  }
}

=head2 sqlscalar

Returns the first row first column value as a scalar.

This works great for selecting one value.

  my $scalar = $dbx->sqlscalar($sql,  @parameters); #returns $
  my $scalar = $dbx->sqlscalar($sql, \@parameters); #returns $
  my $scalar = $dbx->sqlscalar($sql, \%parameters); #returns $

=cut

sub sqlscalar {
  my $self = shift;
  my @data = $self->sqlarray(@_);
  return $data[0];
}

=head2 sqlarray

Returns the SQL result as an array or array reference.

This works great for selecting one column from a table or selecting one row from a table.

  my $array = $dbx->sqlarray($sql,  @parameters); #returns [$,$,$,...]
  my @array = $dbx->sqlarray($sql,  @parameters); #returns ($,$,$,...)
  my $array = $dbx->sqlarray($sql, \@parameters); #returns [$,$,$,...]
  my @array = $dbx->sqlarray($sql, \@parameters); #returns ($,$,$,...)
  my $array = $dbx->sqlarray($sql, \%parameters); #returns [$,$,$,...]
  my @array = $dbx->sqlarray($sql, \%parameters); #returns ($,$,$,...)

=cut

sub sqlarray {
  my $self = shift;
  my $rows = $self->sqlarrayarray(@_);
  my @rows = map {@$_} @$rows;
  return wantarray ? @rows : \@rows;
}

=head2 sqlhash

Returns the first two columns of the SQL result as a hash or hash reference {Key=>Value, Key=>Value, ...}

  my $hash = $dbx->sqlhash($sql,  @parameters); #returns {$=>$, $=>$, ...}
  my %hash = $dbx->sqlhash($sql,  @parameters); #returns ($=>$, $=>$, ...)
  my @hash = $dbx->sqlhash($sql,  @parameters); #this is ordered
  my @keys = grep {!($n++ % 2)} @hash;          #ordered keys

  my $hash = $dbx->sqlhash($sql, \@parameters); #returns {$=>$, $=>$, ...}
  my %hash = $dbx->sqlhash($sql, \@parameters); #returns ($=>$, $=>$, ...)
  my $hash = $dbx->sqlhash($sql, \%parameters); #returns {$=>$, $=>$, ...}
  my %hash = $dbx->sqlhash($sql, \%parameters); #returns ($=>$, $=>$, ...)

=cut

sub sqlhash {
  my $self = shift;
  my @rows = map {$_->[0], $_->[1]} $self->sqlarrayarray(@_);
  return wantarray ? @rows : {@rows};
}

=head2 sqlhashhash

Returns a hash where the keys are the values of the first column and the values are a hash reference of all (including the key) column values.

  my $hash = $dbx->sqlhashhash($sql, @parameters); #returns {$=>{}, $=>{}, ...}
  my %hash = $dbx->sqlhashhash($sql, @parameters); #returns ($=>{}, $=>{}, ...)
  my @hash = $dbx->sqlhashhash($sql, @parameters); #returns ($=>{}, $=>{}, ...) #ordered

=cut

sub sqlhashhash {
  my $self   = shift;
  my $rows   = $self->sqlarrayhashname(@_);
  my $header = shift @$rows;
  my $column = shift @$header;
  my @rows   = map {$_->{$column} => $_} @$rows;
  return wantarray ? @rows : {@rows};
}

=head2 sqlarrayarray

Returns the SQL result as an array or array ref of array references ([],[],...) or [[],[],...]

  my $array = $dbx->sqlarrayarray($sql,  @parameters); #returns [[$,$,...],[],[],...]
  my @array = $dbx->sqlarrayarray($sql,  @parameters); #returns ([$,$,...],[],[],...)
  my $array = $dbx->sqlarrayarray($sql, \@parameters); #returns [[$,$,...],[],[],...]
  my @array = $dbx->sqlarrayarray($sql, \@parameters); #returns ([$,$,...],[],[],...)
  my $array = $dbx->sqlarrayarray($sql, \%parameters); #returns [[$,$,...],[],[],...]
  my @array = $dbx->sqlarrayarray($sql, \%parameters); #returns ([$,$,...],[],[],...)

=cut

sub sqlarrayarray {
  my $self = shift;
  my $sql  = shift;
  return $self->_sqlarrayarray(sql=>$sql, param=>[@_], name=>0);
}

=head2 sqlarrayarrayname

Returns the SQL result as an array or array ref of array references ([],[],...) or [[],[],...] where the first row contains an array reference to the column names

  my $array = $dbx->sqlarrayarrayname($sql,  @parameters); #returns [[$,$,...],[]...]
  my @array = $dbx->sqlarrayarrayname($sql,  @parameters); #returns ([$,$,...],[]...)
  my $array = $dbx->sqlarrayarrayname($sql, \@parameters); #returns [[$,$,...],[]...]
  my @array = $dbx->sqlarrayarrayname($sql, \@parameters); #returns ([$,$,...],[]...)
  my $array = $dbx->sqlarrayarrayname($sql, \%parameters); #returns [[$,$,...],[]...]
  my @array = $dbx->sqlarrayarrayname($sql, \%parameters); #returns ([$,$,...],[]...)

Create an HTML table with L<CGI>

  my $cgi  = CGI->new;
  my $html = $cgi->table($cgi->Tr([map {$cgi->td($_)} $dbx->sqlarrayarrayname($sql, @param)]));

=cut

sub sqlarrayarrayname {
  my $self = shift;
  my $sql  = shift;
  return $self->_sqlarrayarray(sql=>$sql, param=>[@_], name=>1);
}

# _sqlarrayarray
#
# my $array = $dbx->_sqlarrayarray(sql=>$sql, param=>[ @parameters], name=>1);
# my @array = $dbx->_sqlarrayarray(sql=>$sql, param=>[ @parameters], name=>1);
# my $array = $dbx->_sqlarrayarray(sql=>$sql, param=>[ @parameters], name=>0);
# my @array = $dbx->_sqlarrayarray(sql=>$sql, param=>[ @parameters], name=>0);
#
# my $array = $dbx->_sqlarrayarray(sql=>$sql, param=>[\@parameters], name=>1);
# my @array = $dbx->_sqlarrayarray(sql=>$sql, param=>[\@parameters], name=>1);
# my $array = $dbx->_sqlarrayarray(sql=>$sql, param=>[\@parameters], name=>0);
# my @array = $dbx->_sqlarrayarray(sql=>$sql, param=>[\@parameters], name=>0);
#
# my $array = $dbx->_sqlarrayarray(sql=>$sql, param=>[\%parameters], name=>1);
# my @array = $dbx->_sqlarrayarray(sql=>$sql, param=>[\%parameters], name=>1);
# my $array = $dbx->_sqlarrayarray(sql=>$sql, param=>[\%parameters], name=>0);
# my @array = $dbx->_sqlarrayarray(sql=>$sql, param=>[\%parameters], name=>0);

sub _sqlarrayarray {
  my $self = shift;
  my %data = @_;
  my $sth  = $self->sqlcursor($data{'sql'}, @{$data{'param'}}) or die($self->errstr);
  my $name = $sth->{'NAME'}; #DBD::mysql must store this first
  my @rows = ();
  #TODO: replace with fetchall_arrayref
  while (my $row = $sth->fetchrow_arrayref()) {
    push @rows, [@$row];
  }
  unshift @rows, $name if $data{'name'};
  $sth->finish;
  return wantarray ? @rows : \@rows;
}

=head2 sqlarrayhash

Returns the SQL result as an array or array ref of hash references ({},{},...) or [{},{},...]

  my $array = $dbx->sqlarrayhash($sql,  @parameters); #returns [{},{},{},...]
  my @array = $dbx->sqlarrayhash($sql,  @parameters); #returns ({},{},{},...)
  my $array = $dbx->sqlarrayhash($sql, \@parameters); #returns [{},{},{},...]
  my @array = $dbx->sqlarrayhash($sql, \@parameters); #returns ({},{},{},...)
  my $array = $dbx->sqlarrayhash($sql, \%parameters); #returns [{},{},{},...]
  my @array = $dbx->sqlarrayhash($sql, \%parameters); #returns ({},{},{},...)

This method is best used to select a list of hashes out of the database to bless directly into a package.

  my $sql     = q{SELECT COL1 AS "id", COL2 AS "name" FROM TABLE1};
  my @objects = map {bless $_, MyPackage} $dbx->sqlarrayhash($sql,  @parameters);
  my @objects = map {MyPackage->new(%$_)} $dbx->sqlarrayhash($sql,  @parameters);

The @objects array is now a list of blessed MyPackage objects.

=cut

sub sqlarrayhash {
  my $self = shift;
  my $sql  = shift;
  return $self->_sqlarrayhash(sql=>$sql, param=>[@_], name=>0);
}

=head2 sqlarrayhashname

Returns the SQL result as an array or array ref of hash references ([],{},{},...) or [[],{},{},...] where the first row contains an array reference to the column names

  my $array = $dbx->sqlarrayhashname($sql,  @parameters); #returns [[],{},{},...]
  my @array = $dbx->sqlarrayhashname($sql,  @parameters); #returns ([],{},{},...)
  my $array = $dbx->sqlarrayhashname($sql, \@parameters); #returns [[],{},{},...]
  my @array = $dbx->sqlarrayhashname($sql, \@parameters); #returns ([],{},{},...)
  my $array = $dbx->sqlarrayhashname($sql, \%parameters); #returns [[],{},{},...]
  my @array = $dbx->sqlarrayhashname($sql, \%parameters); #returns ([],{},{},...)

=cut

sub sqlarrayhashname {
  my $self = shift;
  my $sql  = shift;
  return $self->_sqlarrayhash(sql=>$sql, param=>[@_], name=>1);
}

# _sqlarrayhash
#
# Returns the SQL result as an array or array ref of hash references ({},{},...) or [{},{},...]
#
# my $array = $dbx->_sqlarrayhash(sql=>$sql, param=>\@parameters, name=>1);
# my @array = $dbx->_sqlarrayhash(sql=>$sql, param=>\@parameters, name=>1);
# my $array = $dbx->_sqlarrayhash(sql=>$sql, param=>\@parameters, name=>0);
# my @array = $dbx->_sqlarrayhash(sql=>$sql, param=>\@parameters, name=>0);

sub _sqlarrayhash {
  my $self = shift;
  my %data = @_;
  my $sth  = $self->sqlcursor($data{'sql'}, @{$data{'param'}}) or die($self->errstr);
  my $name = $sth->{'NAME'}; #DBD::mysql must store this first
  my @rows = ();
  while (my $row = $sth->fetchrow_hashref()) {
    push @rows, {%$row};
  }
  unshift @rows, $name if $data{'name'};
  $sth->finish;
  return wantarray ? @rows : \@rows;
}

=head2 sqlarrayobject

Returns the SQL result as an array of blessed hash objects in to the $class namespace.

  my $array    = $dbx->sqlarrayobject($class, $sql,  @parameters); #returns [bless({}, $class), ...]
  my @array    = $dbx->sqlarrayobject($class, $sql,  @parameters); #returns (bless({}, $class), ...)
  my ($object) = $dbx->sqlarrayobject($class, $sql,  {id=>$id});   #$object is bless({}, $class)

=cut

sub sqlarrayobject {
  my $self    = shift;
  my $class   = shift or die("Error: The sqlarrayobject method requires a class parameter");
  my @objects = map {bless($_, $class)} $self->sqlarrayhash(@_);
  wantarray ? @objects : \@objects;
}

=head2 sqlsort (Oracle Specific?)

Returns the SQL statement with the correct ORDER BY clause given a SQL statement (without an ORDER BY clause) and a signed integer on which column to sort.

  my $sql = $dbx->sqlsort(qq{SELECT 1,'Z' FROM DUAL UNION SELECT 2,'A' FROM DUAL}, -2);

Returns

  SELECT 1,'Z' FROM DUAL UNION SELECT 2,'A' FROM DUAL ORDER BY 2 DESC

Note: The sqlsort method is no longer preferred. It is recommended to use the newer sqlwhere capability.

=cut

sub sqlsort {
  my $self = shift;
  my $sql  = shift;
  my $sort = int(shift); #not sure we need int here but I did not want to change behavior
  if (defined($sort)) {
    my $column    = abs($sort);
    my $direction = $sort < 0 ? "DESC" : "ASC";
    return join " ", $sql, sprintf("ORDER BY %u %s", $column, $direction);
  } else {
    return $sql;
  }
}

=head2 sqlarrayarraynamesort

Returns a sqlarrayarrayname for $sql sorted on column $n where n is an integer ascending for positive, descending for negative, and 0 for no sort.

  my $data = $dbx->sqlarrayarraynamesort($sql, $n,  @parameters);
  my $data = $dbx->sqlarrayarraynamesort($sql, $n, \@parameters);
  my $data = $dbx->sqlarrayarraynamesort($sql, $n, \%parameters);

Note: $sql must not have an "ORDER BY" clause in order for this function to work correctly.

Note: The sqlarrayarraynamesort method is no longer preferred. It is recommended to use the newer sqlwherearrayarrayname capability.

=cut

sub sqlarrayarraynamesort {
  my $self = shift;
  my $sql  = shift;
  my $sort = shift;
  return $self->sqlarrayarrayname($self->sqlsort($sql, $sort), @_);
}

=head1 METHODS (Read) - SQL::Abstract

Please note the "abs" API is a 100% pass through to L<SQL::Abstract>.  Please reference the L<SQL::Abstract> documentation for syntax assistance with that API.

=head2 abscursor

Returns the prepared and executed SQL cursor.

  my $sth = $dbx->abscursor($table, \@columns, \%where, \@order);
  my $sth = $dbx->abscursor($table, \@columns, \%where);          #no order required defaults to storage
  my $sth = $dbx->abscursor($table, \@columns);                   #no where required defaults to all
  my $sth = $dbx->abscursor($table);                              #no columns required defaults to '*' (all)

=cut

sub abscursor {
  my $self = shift;
  return $self->sqlcursor($self->abs->select(@_));
}

=head2 absscalar

Returns the first row first column value as a scalar.

This works great for selecting one value.

  my $scalar = $dbx->absscalar($table, \@columns, \%where, \@order); #returns $

=cut

sub absscalar {
  my $self = shift;
  return $self->sqlscalar($self->abs->select(@_));
}

=head2 absarray

Returns the SQL result as a array.

This works great for selecting one column from a table or selecting one row from a table.

  my @array = $dbx->absarray($table, \@columns, \%where, \@order); #returns ()
  my $array = $dbx->absarray($table, \@columns, \%where, \@order); #returns []

=cut

sub absarray {
  my $self = shift;
  return $self->sqlarray($self->abs->select(@_));
}

=head2 abshash

Returns the first two columns of the SQL result as a hash or hash reference {Key=>Value, Key=>Value, ...}

  my $hash = $dbx->abshash($table, \@columns, \%where, \@order); #returns {}
  my %hash = $dbx->abshash($table, \@columns, \%where, \@order); #returns ()

=cut

sub abshash {
  my $self = shift;
  return $self->sqlhash($self->abs->select(@_));
}

=head2 abshashhash

Returns a hash where the keys are the values of the first column and the values are a hash reference of all (including the key) column values.

  my $hash = $dbx->abshashhash($table, \@columns, \%where, \@order); #returns {}
  my %hash = $dbx->abshashhash($table, \@columns, \%where, \@order); #returns ()

=cut

sub abshashhash {
  my $self = shift;
  return $self->sqlhashhash($self->abs->select(@_));
}


=head2 absarrayarray

Returns the SQL result as an array or array ref of array references ([],[],...) or [[],[],...]

  my $array = $dbx->absarrayarray($table, \@columns, \%where, \@order); #returns [[$,$,...],[],[],...]
  my @array = $dbx->absarrayarray($table, \@columns, \%where, \@order); #returns ([$,$,...],[],[],...)

=cut

sub absarrayarray {
  my $self = shift;
  return $self->sqlarrayarray($self->abs->select(@_));
}

=head2 absarrayarrayname

Returns the SQL result as an array or array ref of array references ([],[],...) or [[],[],...] where the first row contains an array reference to the column names

  my $array = $dbx->absarrayarrayname($table, \@columns, \%where, \@order); #returns [[$,$,...],[],[],...]
  my @array = $dbx->absarrayarrayname($table, \@columns, \%where, \@order); #returns ([$,$,...],[],[],...)

=cut

sub absarrayarrayname {
  my $self = shift;
  return $self->sqlarrayarrayname($self->abs->select(@_));
}

=head2 absarrayhash

Returns the SQL result as an array or array ref of hash references ({},{},...) or [{},{},...]

  my $array = $dbx->absarrayhash($table, \@columns, \%where, \@order); #returns [{},{},{},...]
  my @array = $dbx->absarrayhash($table, \@columns, \%where, \@order); #returns ({},{},{},...)

=cut

sub absarrayhash {
  my $self = shift;
  return $self->sqlarrayhash($self->abs->select(@_));
}

=head2 absarrayhashname

Returns the SQL result as an array or array ref of hash references ({},{},...) or [{},{},...] where the first row contains an array reference to the column names.

  my $array = $dbx->absarrayhashname($table, \@columns, \%where, \@order); #returns [[],{},{},...]
  my @array = $dbx->absarrayhashname($table, \@columns, \%where, \@order); #returns ([],{},{},...)

=cut

sub absarrayhashname {
  my $self = shift;
  return $self->sqlarrayhashname($self->abs->select(@_));
}

=head2 absarrayobject

Returns the SQL result as an array of blessed hash objects in to the $class namespace.

  my $array = $dbx->absarrayobject($class, $table, \@columns, \%where, \@order); #returns [bless({}, $class), ...]
  my @array = $dbx->absarrayobject($class, $table, \@columns, \%where, \@order); #returns (bless({}, $class), ...)

=cut

sub absarrayobject {
  my $self    = shift;
  my $class   = shift or die("Error: The absarrayobject method requires a class parameter");
  my @objects = map {bless($_, $class)} $self->absarrayhash(@_);
  wantarray ? @objects : \@objects;
}

=head1 METHODS (Read) - SQL + SQL::Abstract->where

=head2 sqlwhere

Returns SQL part appended with the WHERE and ORDER BY clauses

  my ($sql, @bind) = $sql->sqlwhere($sqlpart, \%where, \@order);

Note: sqlwhere function should be ported into L<SQL::Abstract> RT125805

=cut

sub sqlwhere {
  my $self           = shift;
  my $sqlpart        = shift;
  my ($where, @bind) = $self->abs->where(@_);
  $sqlpart          .= " $/ $where" if length($where);
  return($sqlpart, @bind);
}

=head2 sqlwherecursor

  my $return = $sql->sqlwherecursor($sqlpart, \%where, \@order);

=cut

sub sqlwherecursor {
  my $self = shift;
  return $self->sqlcursor($self->sqlwhere(@_));
}

=head2 sqlwherescalar

  my $return = $sql->sqlwherescalar($sqlpart, \%where, \@order);

=cut

sub sqlwherescalar {
  my $self = shift;
  return $self->sqlscalar($self->sqlwhere(@_));
}

=head2 sqlwherearray

  my $return = $sql->sqlwherearray($sqlpart, \%where, \@order);

=cut

sub sqlwherearray {
  my $self = shift;
  return $self->sqlarray($self->sqlwhere(@_));
}

=head2 sqlwherehash

  my $return = $sql->sqlwherehash($sqlpart, \%where, \@order);

=cut

sub sqlwherehash {
  my $self = shift;
  return $self->sqlhash($self->sqlwhere(@_));
}

=head2 sqlwherehashhash

  my $return = $sql->sqlwherehashhash($sqlpart, \%where, \@order);

=cut

sub sqlwherehashhash {
  my $self = shift;
  return $self->sqlhashhash($self->sqlwhere(@_));
}

=head2 sqlwherearrayarray

  my $return = $sql->sqlwherearrayarray($sqlpart, \%where, \@order);

=cut

sub sqlwherearrayarray {
  my $self = shift;
  return $self->sqlarrayarray($self->sqlwhere(@_));
}

=head2 sqlwherearrayarrayname

  my $return = $sql->sqlwherearrayarrayname($sqlpart, \%where, \@order);

=cut

sub sqlwherearrayarrayname {
  my $self = shift;
  return $self->sqlarrayarrayname($self->sqlwhere(@_));
}

=head2 sqlwherearrayhash

  my $return = $sql->sqlwherearrayhash($sqlpart, \%where, \@order);

=cut

sub sqlwherearrayhash {
  my $self = shift;
  return $self->sqlarrayhash($self->sqlwhere(@_));
}

=head2 sqlwherearrayhashname

  my $return = $sql->sqlwherearrayhashname($sqlpart, \%where, \@order);

=cut

sub sqlwherearrayhashname {
  my $self = shift;
  return $self->sqlarrayhashname($self->sqlwhere(@_));
}

=head2 sqlwherearrayobject

  my $return = $sql->sqlwherearrayobject($class, $sqlpart, \%where, \@order);

=cut

sub sqlwherearrayobject {
  my $self  = shift;
  my $class = shift or die("Error: sqlwherearrayobject parameter class missing");
  return $self->sqlarrayobject($class, $self->sqlwhere(@_));
}

=head1 METHODS (Write) - SQL

Remember to commit or use AutoCommit

Note: It appears that some drivers do not support the count of rows.

=head2 sqlinsert, insert

Returns the number of rows inserted by the SQL statement.

  my $count = $dbx->sqlinsert( $sql,   @parameters);
  my $count = $dbx->sqlinsert( $sql,  \@parameters);
  my $count = $dbx->sqlinsert( $sql,  \%parameters);

=cut

*sqlinsert = \&sqlupdate;
*insert    = \&sqlupdate;

=head2 sqlupdate, update

Returns the number of rows updated by the SQL statement.

  my $count = $dbx->sqlupdate( $sql,   @parameters);
  my $count = $dbx->sqlupdate( $sql,  \@parameters);
  my $count = $dbx->sqlupdate( $sql,  \%parameters);

=cut

*update    = \&sqlupdate;

sub sqlupdate {
  my $self = shift;
  my $sql  = shift;
  my $sth  = $self->sqlcursor($sql, @_) or die($self->errstr);
  my $rows = $sth->rows;
  $sth->finish;
  return $rows;
}

=head2 sqldelete, delete

Returns the number of rows deleted by the SQL statement.

  my $count = $dbx->sqldelete($sql,   @parameters);
  my $count = $dbx->sqldelete($sql,  \@parameters);
  my $count = $dbx->sqldelete($sql,  \%parameters);

Note: Some Oracle clients do not support row counts on delete instead the value appears to be a success code.

=cut

*sqldelete = \&sqlupdate;
*delete    = \&sqlupdate;

=head2 sqlexecute, execute, exec

Executes stored procedures and generic SQL.

  my $out;
  my $return = $dbx->sqlexecute($sql, $in, \$out);            #pass in/out vars as scalar reference
  my $return = $dbx->sqlexecute($sql, [$in, \$out]);
  my $return = $dbx->sqlexecute($sql, {in=>$in, out=>\$out});

Note: Currently sqlupdate, sqlinsert, sqldelete, and sqlexecute all point to the same method.  This may change in the future if we need to change the behavior of one method.  So, please use the correct method name for your function.

=cut

*sqlexecute = \&sqlupdate;
*execute    = \&sqlupdate;   #deprecated
*exec       = \&sqlupdate;   #deprecated

=head1 METHODS (Write) - SQL::Abstract

=head2 absinsert

Returns the number of rows inserted.

  my $count = $dbx->absinsert($table, \%column_values);

=cut

sub absinsert {
  my $self = shift;
  return $self->sqlinsert($self->abs->insert(@_));
}

=head2 absupdate

Returns the number of rows updated.

  my $count = $dbx->absupdate($table, \%column_values, \%where);

=cut

sub absupdate {
  my $self = shift;
  return $self->sqlupdate($self->abs->update(@_));
}

=head2 absdelete

Returns the number of rows deleted.

  my $count = $dbx->absdelete($table, \%where);

=cut

sub absdelete {
  my $self = shift;
  return $self->sqldelete($self->abs->delete(@_));
}

=head1 METHODS (Write) - Bulk - SQL

=head2 bulksqlinsertarrayarray

Insert records in bulk.

  my @arrayarray = (
                    [$data1, $data2, $data3, $data4, ...],
                    [@row_data_2],
                    [@row_data_3], ...
                   );
  my $count      = $dbx->bulksqlinsertarrayarray($sql, \@arrayarray);

=cut

sub bulksqlinsertarrayarray {
  my $self              = shift;
  my $sql               = shift or die('Error: sql required.');
  my $arrayarray        = shift or die('Error: array of array references required.');
  my $sth               = $self->prepare($sql);
  my $rows              = 0;
  my $size              = @$arrayarray;
  my @tuple_status      = ();
  my ($tupples, $count) = $sth->execute_for_fetch( sub {shift @$arrayarray}, \@tuple_status);
  #print Dumper \@tuple_status, $tupples, $count;
  if (not defined $count) { #driver does not support count yet
    foreach my $status (@tuple_status) {
      if (ref($status) eq "ARRAR") {
        warn($status->[1]);
      } elsif ($status == -1) {
        $rows++; #no error assume 1 row inserted.
      } else {
        warn(Dumper $status);
      }
    }
    $count = $rows;
  }
  return $count;
}

=head2 bulksqlinsertarrayhash

Insert records in bulk.

  my @columns   = ("Col1", "Col2", "Col3", "Col4", ...);                         #case sensitive with respect to @arrayhash
  my @arrayhash = (
                   {C0l1=>data1, Col2=>$data2, Col3=>$data3, Col4=>$data4, ...}, #extra hash items ignored when sliced using @columns
                   \%row_hash_data_2,
                   \%row_hash_data_3, ...
                  );
  my $count     = $dbx->bulksqlinsertarrayhash($sql, \@columns, \@arrayhash);

=cut

sub bulksqlinsertarrayhash {
  my $self       = shift;
  my $sql        = shift or die("Error: SQL required.");
  my $columns    = shift or die("Error: columns array reference required.");
  my $arrayhash  = shift or die("Error: array of hash references required.");
  my @arrayarray = map {my %hash = %$_; my @slice = @hash{@$columns}; \@slice} @$arrayhash;
  return $self->bulksqlinsertarrayarray($sql, \@arrayarray);
}

=head2 bulksqlinsertcursor

Insert records in bulk.

Step 1 select data from table 1 in database 1

  my $sth1  = $dbx1->sqlcursor('Select Col1 AS "ColA", Col2 AS "ColB", Col3 AS "ColC" from table1');

Step 2 insert in to table 2 in database 2

  my $count = $dbx2->bulksqlinsertcursor($sql, $sth1);

Note: If you are inside a single database, it is much more efficient to use insert from select syntax as no data needs to be transferred to and from the client.

=cut

sub bulksqlinsertcursor {
  my $self         = shift;
  my $sql          = shift or die('Error: sql required.');
  my $cursor       = shift or die('Error: cursor required.');
  my $sth          = $self->prepare($sql);
  my @tuple_status = ();
  my $size         = 0;
  my $count        = $sth->execute_for_fetch( sub {my $row = $cursor->fetchrow_arrayref; $size++ if $row; return $row}, \@tuple_status);
  unless ($count == $size) {
    warn Dumper \@tuple_status; #TODO better error trapping...
  }
  return $count;
}

=head2 bulksqlupdatearrayarray

Update records in bulk.

  my @arrayarray   = (
                      [$data1, $data2, $data3, $data4, $id],
                      [@row_data_2],
                      [@row_data_3], ...
                     );
  my $count        = $dbx->bulksqlupdatearrayarray($sql, \@arrayarray);

=cut

sub bulksqlupdatearrayarray {
  my $self              = shift;
  my $sql               = shift or die('Error: sql required.');
  my $arrayarray        = shift or die('Error: array of array references required.');
  my $sth               = $self->prepare($sql);
  my $size              = @$arrayarray;
  my @tuple_status      = (); #pass to set $tupples
  my ($tupples, $count) = $sth->execute_for_fetch( sub {shift @$arrayarray}, \@tuple_status);
  warn("Warning: Attempted $size transactions but only $tupples where successful.") unless $size == $tupples;
  #warn Dumper \@tuple_status;
  unless (defined($count) and $count >= 0) {
    $count = sum(0, grep {$_ > 0} grep {not ref($_)} @tuple_status);
  }
  return $count;
}

=head1 METHODS (Write) - Bulk - SQL::Abstract-like

These bulk methods do not use L<SQL::Abstract> but our own similar SQL insert and update methods.

=head2 bulkabsinsertarrayarray

Insert records in bulk.

  my @columns    = ("Col1", "Col2", "Col3", "Col4", ...);
  my @arrayarray = (
                    [data1, $data2, $data3, $data4, ...],
                    [@row_data_2],
                    [@row_data_3], ...
                   );
  my $count      = $dbx->bulkabsinsertarrayarray($table, \@columns, \@arrayarray);

=cut

sub bulkabsinsertarrayarray {
  my $self         = shift;
  my $table        = shift or die('Error: table name required.');
  my $columns      = shift or die('Error: columns array reference required.');
  my $arrayarray   = shift or die('Error: array of array references required.');
  my $sql          = $self->_bulkinsert_sql($table => $columns);
  return $self->bulksqlinsertarrayarray($sql, $arrayarray);
}

=head2 bulkabsinsertarrayhash

Insert records in bulk.

  my @columns   = ("Col1", "Col2", "Col3", "Col4", ...);                           #case sensitive with respect to @arrayhash
  my @arrayhash = (
                   {C0l1=>data1, Col2=>$data2, Col3=>$data3, Col4=>$data4, ...}, #extra hash items ignored when sliced using @columns
                   \%row_hash_data_2,
                   \%row_hash_data_3, ...
                  );
  my $count     = $dbx->bulkabsinsertarrayhash($table, \@columns, \@arrayhash);

=cut

sub bulkabsinsertarrayhash {
  my $self       = shift;
  my $table      = shift or die("Error: table name required.");
  my $columns    = shift or die("Error: columns array reference required.");
  my $arrayhash  = shift or die("Error array of hash references required");
  my @arrayarray = map {my %hash = %$_; my @slice = @hash{@$columns}; \@slice} @$arrayhash;
  return $self->bulkabsinsertarrayarray($table, $columns, \@arrayarray);
}

=head2 bulkabsinsertcursor

Insert records in bulk.

Step 1 select data from table 1 in database 1

  my $sth1  = $dbx1->sqlcursor('Select Col1 AS "ColA", Col2 AS "ColB", Col3 AS "ColC" from table1');

Step 2 insert in to table 2 in database 2

  my $count = $dbx2->bulkabsinsertcursor($table2, $sth1);

  my $count = $dbx2->bulkabsinsertcursor($table2, \@columns, $sth1); #if your DBD/API does not support column alias support

Note: If you are inside a single database, it is much more efficient to use insert from select syntax as no data needs to be transferred to and from the client.

=cut

sub bulkabsinsertcursor {
  my $self         = shift;
  my $table        = shift or die('Error: table name required.');
  my $cursor       = pop   or die('Error: cursor required.');
  my $columns      = shift || $cursor->{'NAME'};
  my $sql          = $self->_bulkinsert_sql($table => $columns);
  return $self->bulksqlinsertcursor($sql, $cursor);
}

#head2 _bulkinsert_sql
#
#Our own method since SQL::Abstract does not support ordered column values
#
#cut

sub _bulkinsert_sql {
  my $self    = shift;
  my $table   = shift;
  my $columns = shift;
  my $sql     = sprintf("INSERT INTO $table (%s) VALUES (%s)", join(',', @$columns), join(',', map {'?'} @$columns));
  #warn "$sql\n";
  return $sql;
}

=head2 bulkabsupdatearrayarray

Update records in bulk.

  my @setcolumns   = ("Col1", "Col2", "Col3", "Col4");
  my @wherecolumns = ("ID");
  my @arrayarray   = (
                      [$data1, $data2, $data3, $data4, $id],
                      [@row_data_2],
                      [@row_data_3], ...
                     );
  my $count        = $dbx->bulkabsupdatearrayarray($table, \@setcolumns, \@wherecolumns, \@arrayarray);

=cut

sub bulkabsupdatearrayarray {
  my $self         = shift;
  my $table        = shift or die('Error: table name required.');
  my $setcolumns   = shift or die('Error: set columns array reference required.');
  my $wherecolumns = shift or die('Error: where columns array reference required.');
  my $arrayarray   = shift;
  my $sql          = $self->_bulkupdate_sql($table => $setcolumns, $wherecolumns);
  return $self->bulksqlupdatearrayarray($sql, $arrayarray);
}

#head2 _bulkupdate_sql
#
#Our own method since SQL::Abstract does not support ordered column values
#
##cut

sub _bulkupdate_sql {
  my $self         = shift;
  my $table        = shift;
  my $setcolumns   = shift;
  my $wherecolumns = shift;
  my $sql          = sprintf("UPDATE $table SET %s WHERE %s", join(", ", map {"$_ = ?"} @$setcolumns), join(" AND ", map {"$_ = ?"} @$wherecolumns));
  #warn "$sql\n";
  return $sql;
}

=head1 Constructors

=head2 abs

Returns a L<SQL::Abstract> object

=cut

sub abs {
  my $self       = shift;
  $self->{'abs'} = shift if @_;
  unless (defined $self->{'abs'}) {
    eval 'use SQL::Abstract'; #run time require so as not to require installation for all users
    my $error      = $@;
    die($error) if $error;
    $self->{'abs'} = SQL::Abstract->new;
  }
  return $self->{'abs'};
}

=head1 Methods (Informational)

=head2 dbms_name

Return the DBMS Name (e.g. Oracle, MySQL, PostgreSQL)

=cut

sub dbms_name {shift->dbh->get_info(17)};

=head1 Methods (Session Management)

These methods allow the setting of Oracle session features that are available in the v$session table.  If other databases support these features, please let me know.  But, as it stands, these methods are non operational unless SQL_DBMS_NAME is Oracle.

=head2 module

Sets and returns the v$session.module (Oracle) value.

Note: Module is set for you by DBD::Oracle.  However you may set it however you'd like.  It should be set once after connection and left alone.

  $dbx->module("perl@host");      #normally set by DBD::Oracle
  $dbx->module($module, $action); #can set initial action too.
  my $module = $dbx->module();

=cut

sub module {
  my $self = shift;
  return unless $self->dbms_name eq 'Oracle';
  if (@_) {
    my $module = shift;
    my $action = shift;
    $self->sqlexecute($self->_set_module_sql, $module, $action);
  }
  if (defined wantarray) {
    return $self->sqlscalar($self->_sys_context_userenv_sql, 'MODULE');
  } else {
    return; #void context no need to hit the database
  }
}

sub _set_module_sql {
  return qq{/* be655786-bcbe-11e5-8338-005056a31307 */
            /* Script: $0 */
            /* Package: $PACKAGE */
            /* Method: _set_module_sql */
            BEGIN
              DBMS_APPLICATION_INFO.set_module(module_name => ?, action_name => ?);
            END;
           };
}

=head2 client_info

Sets and returns the v$session.client_info (Oracle) value.

  $dbx->client_info("Running From crontab");
  my $client_info = $dbx->client_info();

You may use this field for anything up to 64 characters!

  $dbx->client_info(join "~", (ver => 4, realm => "ldap", grp =>25)); #tilde is a fairly good separator
  my %client_info = split(/~/, $dbx->client_info());

=cut

sub client_info {
  my $self = shift;
  return unless $self->dbms_name eq 'Oracle';
  if (@_) {
    my $text = shift;
    $self->sqlexecute($self->_set_client_info_sql, $text);
  }
  if (defined wantarray) {
    return $self->sqlscalar($self->_sys_context_userenv_sql, 'CLIENT_INFO');
  } else {
    return; #void context no need to hit the database
  }
}

sub _set_client_info_sql {
  return qq{/* d04d0138-bcbe-11e5-b0e3-005056a31307 */
            /* Script: $0 */
            /* Package: $PACKAGE */
            /* Method: _set_client_info_sql */
            BEGIN
              DBMS_APPLICATION_INFO.set_client_info(client_info => ?);
            END;
           };
}

=head2 action

Sets and returns the v$session.action (Oracle) value.

  $dbx->action("We are Here");
  my $action = $dbx->action();

Note: This should be updated fairly often. Every loop if it runs for more than 5 seconds and may end up in V$SQL_MONITOR.

  while ($this) {
    local $dbx->{'action'} = "This Loop"; #tied to the database with a little Perl sugar
  }

=cut

sub action {
  my $self = shift;
  return unless $self->dbms_name eq 'Oracle';
  if (@_) {
    my $text = shift;
    $self->sqlexecute($self->_set_action_sql, $text);
  }
  if (defined wantarray) {
    return $self->sqlscalar($self->_sys_context_userenv_sql, 'ACTION');
  } else {
    return; #void context no need to hit the database
  }
}

sub _set_action_sql {
  return qq{/* e682f1a6-bcbe-11e5-bd3e-005056a31307 */
            /* Script: $0 */
            /* Package: $PACKAGE */
            /* Method: _set_action_sql */
            BEGIN
              DBMS_APPLICATION_INFO.set_action(action_name => ?);
            END;
           };
}

=head2 client_identifier

Sets and returns the v$session.client_identifier (Oracle) value.

  $dbx->client_identifier($login);
  my $client_identifier = $dbx->client_identifier();

Note: This should be updated based on the login of the authenticated end user.  I use the client_info->{'realm'} if you have more than one authentication realm.

For auditing add this to an update trigger

  new.UPDATED_USER = sys_context('USERENV', 'CLIENT_IDENTIFIER');

=cut

sub client_identifier {
  my $self = shift;
  return unless $self->dbms_name eq 'Oracle';
  if (@_) {
    my $text = shift;
    $self->sqlexecute($self->_set_client_identifier_sql, $text);
  }
  if (defined wantarray) {
    return $self->sqlscalar($self->_sys_context_userenv_sql, 'CLIENT_IDENTIFIER');
  } else {
    return; #void context no need to hit the database
  }
}

sub _set_client_identifier_sql {
  return qq{/* f8226e6e-bcbe-11e5-91b8-005056a31307 */
            /* Script: $0 */
            /* Package: $PACKAGE */
            /* Method: _set_client_identifier_sql */
            BEGIN
              DBMS_SESSION.SET_IDENTIFIER(client_id => ?);
            END;
           };
}

sub _sys_context_userenv_sql {
  return qq{/* 09648e1e-bcbf-11e5-916a-005056a31307 */
            /* Script: $0 */
            /* Package: $PACKAGE */
            /* Method: _sys_context_userenv_sql */
            SELECT sys_context('USERENV',?)
              FROM SYS.DUAL
           };
}

=head1 TODO

Sort functions sqlsort and sqlarrayarraynamesort may not be portable. It is now recommend to use sqlwhere methods instead.

Add some kind of capability to allow hash binds to bind as some native type rather than all strings.

Hash binds scan comments for bind variables e.g. /* :variable */

Improve error messages

=head1 BUGS

Please open on GitHub

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT

MIT License

Copyright (c) 2023 Michael R. Davis

=head1 SEE ALSO

=head2 The Competition

L<DBIx::DWIW>, L<DBIx::Wrapper>, L<DBIx::Simple>, L<Data::Table::fromSQL>, L<DBIx::Wrapper::VerySimple>, L<DBIx::Raw>, L<Dancer::Plugin::Database> quick_*, L<Mojo::Pg::Results> (arrays & hashes)

=head2 The Building Blocks

L<DBI>, L<SQL::Abstract>

=cut

1;
