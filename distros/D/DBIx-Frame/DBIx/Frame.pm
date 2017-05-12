$VERSION = "1.06";
package DBIx::Frame;
our $VERSION = "1.06";

# -*- Perl -*- 		Wed May 26 09:23:06 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@ks.uiuc.edu>
# Copyright 2000-2004, Tim Skirvin and UIUC Board of Trustees.  
# Redistribution terms are below.
###############################################################################

=head1 NAME

DBIx::Frame - a perl module for creating and maintaining DBI frameworks

=head1 SYNOPSIS

  use DBIx::Frame;
  DBIx::Frame->init('server', 'dbtype') || exit(0);
  my $DB = DBIx::Frame->new('database', 'user', 'pass') 
    or die("Couldn't connect to database: ", DBI->errstr);

See below for how to actually use this object.

=head1 DESCRIPTION

DBIx::Frame is an extension of the standard DBI perl module, designed
around mysql, and used to create and maintain frameworks for databases.
It has query logging, and a standardized interface for standard SQL
statements like 'update' and 'insert' that doesn't require understanding
SQL to any great degree.  Ideally, the user or developer shouldn't have to
know too much SQL to be able to administer a database.  On the other hand,
it does require a certain setup that isn't necessarily easy to pick up,
and isn't standard SQL - with all the problems that this entails.  

Database design is discussed below.

=cut

use strict;
use DBI;
use SelfLoader;
require Exporter;

use vars qw( $SERVER $DBTYPE $USER $PASS $DBNAME %FIELDS %KEYS %LIST %HTML 
	     %REQUIRED %ADMIN %TEXT %ORDER $DEBUG $ERROR );
$DEBUG ||= 0;		# Default of $DEBUG is 0 - must set it elsewhere

SelfLoader->load_stubs();	# Prepare module so it can be loaded elsewhere

1;

__DATA__	# Comment me out to test the functions without SelfLoader;

=head1 USAGE

There are five main sections of usage - database connection, DBI
directives, error/logging functions, database structure queries, and
helper functions.

=head2 Database Connection

=over 4

=item init ( SERVER, DBTYPE, DATABASE [, USER [, PASS ]] )

Initializes the variables necessary to connect to a database.  C<SERVER>, 
C<DBTYPE>, and C<DATABASE> are necessary to determine what to connect to; 
C<USER> and C<PASS> are optional.  Returns 1 if successful, 0 otherwise.

=cut

sub init {
  my ($class, $server, $dbtype, $database, $user, $pass, $dbname) = @_;
  $SERVER = $server   || $SERVER || "localhost";
  $DBTYPE = $dbtype   || $DBTYPE || "mysql";
  $DBNAME = $database || $DBNAME || "";
  $USER   = $user     || $USER   || "";    
  $PASS   = $pass     || $PASS   || "";
  1;
}

=item new ( DATABASE [, USER [, PASS [, SERVER [, DBTYPE ]]]] )

=item connect ( [ DATABASE [, USER [, PASS [, SERVER [, DBTYPE ]]]]] )

Creates a connection to the database, and returns a new DBIx::Frame object.  
C<DATABASE>, C<PASS>, etc are only necessary to override the defaults set
with C<init()>, or if they were never set in the first place.

If unsuccessful, returns undef; may also leave an error message in 
DBI->errstr, if the error was in the DBI connection phase.

=cut

sub new { shift->connect(@_) }
sub connect { 
  my ($class, $database, $user, $pass, $server, $dbtype, %args) = @_;
  $dbtype   ||= $DBTYPE;  $server ||= $SERVER;
  $user     ||= $USER;    $pass   ||= $PASS;
  $database ||= $DBNAME;

  return undef unless ($dbtype && $server && $database);
  my $self = {};
  my $db = DBI->connect("DBI:$dbtype:$database:$server", 
		$user || undef, $pass || undef, ref %args ); 
  unless ( $db ) { $ERROR = DBI->errstr; return undef; }
  
  # Internal data - just keeps track of stuff that might come in handy 
  # later, but which we aren't telling the world about.  It couldn't hurt.
  $$self{'DATABASE'} = $database || undef;
  $$self{'DBTYPE'}   = $dbtype   || undef; $$self{'SERVER'} = $server || undef;
  $$self{'USER'}     = $user     || undef; $$self{'PASS'}   = $pass   || undef;
  $$self{'ARGS'}     = \%args    || {};
  $$self{'DBNAME'}   = $DBNAME   || $database || undef;

  # Public data - things that the users will modify. 
  $$self{'DB'}       = $db; 		$$self{'ERROR'}    = undef;
  $$self{'FIELDS'}   = \%FIELDS; 	$$self{'ADMIN'}    = \%ADMIN;
  $$self{'LIST'}     = \%LIST; 		$$self{'ORDER'}    = \%ORDER;
  $$self{'KEYS'}     = \%KEYS; 		$$self{'REQUIRED'} = \%REQUIRED;
  $$self{'HTML'}     = \%HTML; 		$$self{'TEXT'}     = \%TEXT;
  $$self{'QUERIES'}  = [];

  bless $self, $class; 
  $self;
}

=item table_add ( NAME, FIELDS [, KEYS, LIST, ORDER, ADMIN, REQUIRED, HTML, TEXT ] ) 

Adds a table to the database object.  C<NAME> is the name of the table,
and C<FIELDS> is a hash reference to the list of fields and data types;
these are the only two required entries, but the others are helpful.
For more information on what they are, see below.

(Note that if init() is not run first, and you're invoking this without an
item, you could break things down the line.  It's best to go ahead and run
init() first.)

=cut

sub table_add {
  my ($self, $name, $fields, $keys, $list, $order, $admin, $required,
 	$html, $text, @rest) = @_;
  return undef unless ($name && $fields && ref $fields);

  $self->set_fields(   $name, $fields);
  $self->set_admin(    $name, $admin || '');
  $self->set_list(     $name, $list  || [ keys %{$fields} ]);
  $self->set_order(    $name, $order || 'ID');
  $self->set_keys(     $name, $keys  || 'ID' );
  $self->set_required( $name, $required || $keys || 'ID');
  $self->set_html(     $name, $html  || sub { "No table available" });
  $self->set_text(     $name, $html  || sub { "No text available" });

  1;
}

=item add_table ( NAME, FIELDS [, KEY, LIST, HTML, TEXT ] ) 

Deprecated; adds a table to the database object.  C<NAME> is the name of
the table, C<FIELDS> is a hash reference to the list of fields and data
types, C<KEY> and C<LIST> are array references, and C<HTML> and C<TEXT>
are code references.  table_add() offers things in a more logical order.

=cut

sub add_table {
  my ($self, $name, $fields, $keys, $list, $html, $text, @rest) = @_;
  return undef unless $name;
  return undef unless ($fields && ref $fields);

  my $package = $self->_database;

  $self->set_fields($name, $fields);
  $self->set_keys($name, $keys || 'ID' );
  $self->set_list($name, $list || [ keys %{$fields} ]);

  $self->set_html($name, $html || sub { "No table available" });
  $self->set_text($name, $html || sub { "No text available" });

  1;
}

=item set_fields ( NAME, HASHREF )

=item set_keys ( NAME, KEYINFO )

=item set_admin ( NAME, ARRAYREF ) 

=item set_list ( NAME, ARRAYREF )

=item set_order ( NAME, ARRAYREF )

=item set_required ( NAME, ARRAYREF ) 

=item set_html ( NAME, CODEREF )

=item set_text ( NAME, CODEREF )

Sets the C<FIELDS>, C<KEYS>, C<ADMIN>, C<LIST>, C<ORDER>, C<REQUIRED>,
C<HTML>, and C<TEXT> fields, respectively, for the given NAME in the
database object.  These do the actual work of add_table(), or can be
invoked individually so that individual scripts can use their own HTML
formatting and such.

=cut

sub _set {
  my ($self, $hash, $name, $fields) = @_;
  return undef unless $name;

  my $package = $self->_database;

  $$hash{$package} ||= {};
  my $fullhash = $$hash{$package} || {};
  $fields ? $$fullhash{$name} = $fields : $$fullhash{$name};
}

sub set_fields   { shift->_set(\%DBIx::Frame::FIELDS,   @_) }
sub set_admin    { shift->_set(\%DBIx::Frame::ADMIN,    @_) }
sub set_list     { shift->_set(\%DBIx::Frame::LIST,     @_) }
sub set_order    { shift->_set(\%DBIx::Frame::ORDER,    @_) }
sub set_keys     { shift->_set(\%DBIx::Frame::KEYS,     @_) }
sub set_required { shift->_set(\%DBIx::Frame::REQUIRED, @_) }
sub set_html     { shift->_set(\%DBIx::Frame::HTML,     @_) }
sub set_text     { shift->_set(\%DBIx::Frame::TEXT,     @_) }

=item db () 

Returns a reference to the database that the object connects to.  This
references is a standard DBI object.  

=cut

sub db { $_[0]{DB} }

=item connected ()

Returns 1 if currently connected, 0 otherwise.

=cut

sub connected { $_[0]{DB} ? 1 : 0 }

=item disconnect ()

Disconnects from the database.  The logged queries and errors are left 
alone.

=cut

sub disconnect { $_[0]->{'DB'}->disconnect if $_[0]->db }

=back

=head2 DBI/SQL Functions

Note: several of these functions refer to C<DATAHASH>.  This is simply
a hash reference that has key/value pairs that correspond to those in 
the database's structure.  Any key/value pairs that do not correspond to 
the structure are dropped before any SQL transactions are performed.

=over 4

=item invoke ( QUERY )

Invokes an arbitrary C<QUERY> on the connected database, and logs the 
query.  If the query is successful, returns the appropriate return value
(as laid out in the DBI standard); if unsuccesful, sets the error value 
and returns 'undef'.  

(This is essentially the same as preparing and executing a query in
standard DBI, with logging, checks for connections, etc.)

=cut

sub invoke {
  my ($self, $query) = @_;
  my $db = _db_or_die($self) || return undef;
  return undef unless defined($query);
  $self->add_query($query);
  my $return = $db->prepare($query)->execute;
  $return ? $return : $self->set_error(DBI->errstr) && return undef;
}

=item func ( FUNCTION )

Invokes C<FUNCTION> on the database, using C<DBI->func>.

=cut

sub func { my $db = _db_or_die(shift) || return undef; $db->func(@_) }

=item quote ( LINE [, LINE [, LINE [...]]] )

=item neat ( LINE, LENGTH )

=item neat_list ( ARRAY, LENGTH [, FIELDSEP ] )

Invokes DBI->quote, DBI->neat, and DBI->neat_list on their inputs, which
are the same as the equivalent DBI functions.  See their man pages for more 
information.

=cut

sub quote     { shift->db->quote(@_) }
sub neat      { shift->db->neat(@_) }
sub neat_list { shift->db->neat_list(@_) }

=item insert ( TABLE, DATAHASH [, ALLOW_ADMIN] )

Creates and executes an SQL query to insert an item into C<TABLE>, using 
the data from C<DATAHASH>.  All of the KEY values must be set, and no entry
must already exist that matches all of the KEYs; if either problem exists, 
then this function will fail.  Uses C<invoke()>.  

If C<ALLOW_ADMIN> is set, then you may work with fields that are protected
by the C<ADMIN> array.  (This doesn't actually work yet.)

=cut

sub insert {
  my ($self, $table, $datahash, $admin, @other)  = @_;  
  my $db = _db_or_die($self) || return undef;
  $self->_test_table($table) || return undef;	

  # Parse the insert information
  my $hash   = $self->_parse_hash($table, $datahash);
  unless ($hash) {
    $self->set_error("No data to insert into table '$table'");
    return undef;
  }

  # Unless we get an 'admin' flag, then don't let us work on admin fields
  my %present;
  unless ($admin) { 
    foreach my $field ($self->admin($table)) { 
      $present{$field}++ if 
	(defined $$datahash{$field} && $$datahash{$field} !~ m/^\s*$/);
    }
  }

  # Are all fields in 'required' present?
  my (%missing, %check);
  foreach my $field ($self->required($table)) {
    next if ($field eq 'ID');
    my $info = $$datahash{$field};  
    next unless defined $info; $info =~ s%^\s+|\s+$%%g; next if $info ne '';
    $missing{$field}++;
  }

  # Are all fields in 'key' present, and the entry used by 'key' unique?
  foreach my $field ($self->key($table)) { 
    if (defined $$datahash{$field} && $$datahash{$field} !~ m/^\s*$/) { 
      $check{$field} = $$datahash{$field}; 
    } else { $missing{$field}++ }
  }

  if (scalar keys %missing) {
    $self->set_error("Not all required fields set: still need " . 
		join(', ', keys %missing) );  
    return undef;
  } else {
    my @existing = $self->select($table, \%check);
    if (scalar @existing) { 
      $self->set_error("Entry already exists") && return undef;
    }
  }

  # We're good to go - proceed
  my $keys   = join(', ', keys %{$hash} ); 
  my $values = join(', ', values %{$hash} );  
  my $query = "INSERT INTO $table ( $keys ) VALUES ( $values )";

  $self->invoke($query);
}

=item update ( TABLE, DATAHASH, SELECTHASH [, ALLOW_ADMIN] )

Creates and executes an SQL query to update an item from C<TABLE>, using 
the (new) data from C<DATAHASH> for the updated values and the (old) data 
from C<SELECTHASH> to determine which item to update.  Note that the
search terms won't be empty unless you specifically specify them so. Uses
C<invoke()>.  

If C<ALLOW_ADMIN> is set, then you may work with fields that are protected
by the C<ADMIN> array.  (This doesn't actually work yet.)

=cut

sub update {
  my ($self, $table, $datahash, $selecthash, $admin ) = @_;
  my $db = _db_or_die($self) || return undef;
  $self->_test_table($table) || $self->set_error("Bad table") &&  return undef;

  my $hash   = $self->_parse_hash($table, $datahash)    || {};
  my $select = $self->_make_select($table, $selecthash, 0, 1) || "";
  unless ($select) {
    my @return = keys %{$selecthash};  my $return = join(', ', @return);
    $self->set_error("Couldn't get a selection out of $return");
    return undef;
  }

  my @list;
  foreach (keys %{$hash}) { 
    next unless defined($_) && defined($$hash{$_}); 
    $$hash{$_} =~ s%(^\s+|\s+$)%%;	# Lose the leading/trailing whitespace
    push (@list, "$_ = $$hash{$_}") 
  }

  # Unless we get an 'admin' flag, then don't let us work on admin fields
  my %present;
  unless ($admin) { 
    foreach my $field ($self->admin($table)) { 
      $present{$field}++ if 
	(defined $$datahash{$field} && $$datahash{$field} !~ m/^\s*$/);
    }
  }

  my $setlist = join(', ', @list);
  unless ($table && $setlist && $select) {
    $self->set_error("Not enough unformation for the update " . 
		                    "(S: $setlist S: $select)" );
    return undef;
  }
  my $query = "UPDATE $table SET $setlist $select";

  $self->invoke($query);
}

=item select ( TABLE, DATAHASH [, LIMITHASH [, OTHER]] )

Creates and executes an SQL query to select an item or items from C<TABLE>, 
using the data from C<DATAHASH> for the selection.  Uses C<MATCHHASH> to
offer extra information to the select query - specifically, :
 
  Key	  Description
  MATCH	  What fields to return; defaults to '*'.
  ORDER	  What order to return the fields in.  Defaults to the value of 
	  order() for this database/table.  See below for more details.

C<OTHER> adds additional text to the end of the search.

Returns a list of hash refs, each of which is one entry from the table.

Note that this does *not* use C<invoke()>, though standard logging is
still done.  This is done to preserve the order that the database returned
its results in.

=cut

sub select {
  my ($self, $table, $datahash, $limit, $other, @extra) = @_;
  my $db = _db_or_die($self) || return undef;
  $table ||= {};  $limit ||= {};  $other ||= "";
  $self->_test_table($table) || return undef;

  # If LIMITHASH is actually a scalar, assume that this was the value of 
  # $limit{MATCH} (this was what it used to be before).
  if (ref($limit) eq '') { my $m = $limit; $limit = {};  $$limit{'MATCH'} = $m }

  # Make the query; note that _make_select() does most of the work.
  my $match = $$limit{'MATCH'} || "*"; 
  my $select = $self->_make_select($table, $datahash, $limit, 0, @extra) || "";
  my $query = "SELECT $match FROM $table $select $other";

  return undef unless $query;

  # Do the stuff that invoke would normally do
  $self->add_query($query);
  my $sth = $db->prepare($query);
  my $return = $sth->execute;  
  unless ($return) { $self->set_error(DBI->errstr) && return undef }

  # Get the results
  my @return;
  while (my $val = $sth->fetchrow_hashref) { push (@return, $val) }
  @return;
}

=item select_multi ( TABLEHASHREF [, LIMITHASH [, OTHER]] ) 

Creates and executes an SQL query to select an item or items from more
than one table.  C<TABLEHASHREF> is a hash reference, where the hash's
keys are the tables to select from and the values are DATAHASH references
(as in B<select()>).  Returns a list of hash refs, each of which is one 
entry from the combined tables.  The keys these hash references take the
form of "TABLE.ITEM".

Does *not* use C<invoke()>, though standard logging is still done.

Note that C<LIMITHASH> is not currently used; while the author expects to
get to this at some point, it hasn't been done yet.  For now, the API is
better off leaving it in.

=cut

sub select_multi {
  my ($self, $tablehash, $limithash, $other, @extra) = @_;
  my $db = _db_or_die($self) || return undef;
  my $match = "*";  $other ||= "";

  # Create a complete hash out of all of the different hashes, using the
  # table names as extra indices.

  ( $self->set_error("Bad usage: select_multi()") && return undef )  
					unless ref $tablehash;
  my (%fullhash, @fields, @original);
  foreach my $table (keys %{$tablehash}) {
    $self->_test_table($table) || next;
    foreach (sort keys %{$self->fields($table)}) { 
      push @fields, \$_; push @original, "$table.$_";
    }
    my $hash = $$tablehash{$table};
    foreach (keys %{$hash}) { $fullhash{"$table.$_"} = $$hash{$_} }
  }

  # May eventually want to do something with 'match' as well

  my $table = join(", ", keys %{$tablehash});
  my $select = $self->_make_select_multi(
                [ keys %{$tablehash} ], \%fullhash, @extra ) || "";
  my $query = "SELECT $match FROM $table $select $other";

  return undef unless $query;

  # Do the stuff that invoke would normally do
  $self->add_query($query);
  my $sth = $db->prepare($query);
  my $return = $sth->execute;  
  unless ($return) { $self->set_error(DBI->errstr) && return undef }
  $sth->bind_columns( @fields );

  # Get the results, and reformat them appropriately
  my @return;
  while (my $val = $sth->fetchrow_arrayref) { 
    my %hash;
    for (my $i = 0; $i < @$val; $i++) {
      my $field = $original[$i]; my $value = $$val[$i];  
      $hash{$field} = $value; 
    }
    push @return, \%hash;
  }
  @return;
}

=item delete ( TABLE, DATAHASH )

Creates and executes an SQL query to remove an item from C<TABLE>, using 
the data from C<DATAHASH> to select which item to remove.  Uses C<invoke()>.

=cut

sub delete {
  my ($self, $table, $datahash) = @_;
  return undef unless ($datahash && ref $datahash);
  my $db = _db_or_die($self) || return undef;
  $self->_test_table($table) || return undef;

  my $select = $self->_make_select($table, $datahash, 0, 1) || return undef;
  $select =~ s/ORDER BY.*//;	# Deletes don't need these
  my $query = "DELETE FROM $table $select";

  $self->invoke($query);
}

=item create_table ( TABLE, HASH )

Creates and executes an SQL query to create a table named C<TABLE>, based 
on C<HASH>.  Fails and returns undef if it already exists. Uses C<invoke()>.

=cut

sub create_table {
  my ($self, $table, $hash) = @_;
  my $db = _db_or_die($self) || return undef;

  # Figure out if we can actually create this table
  unless ($table) { $self->set_error("No table to create");  return undef }
  if ($self->_test_table($table)) { 
    $self->set_error("Table '$table' already exists");  
    return undef;
  } else { $self->clear_error(); }

  $hash ||= $self->fieldhash->{$table};
  return undef unless ref $hash;

  # Create the query
  my @query;
  foreach (sort keys %{$hash}) { push(@query, "$_ $$hash{$_}"); }
  my $query = "CREATE TABLE $table ( " . join(', ', @query) . " )";
  
  # Perform the query
  $self->invoke($query);
}

=item drop_table ( TABLE )

Drops the table C<TABLE>.  Note, this is dangerous - you will lose all of
your data in the table.  Returns undef if C<TABLE> doesn't exist.  
Uses C<invoke()>.

=cut

sub drop_table {
  my ($self, $table) = @_;
  my $db = _db_or_die($self) || return undef;
  $self->_test_table($table) || return undef;
  my $query = "DROP TABLE $table";	
  $self->invoke($query);
}

=item reset_table ( TABLE )

Drops and then re-creates C<TABLE>.  Uses C<create_table()> and
C<drop_table()>.  Again, this is dangerous.

=cut

sub reset_table { $_[0]->drop_table($_[1]) && $_[0]->create_table($_[1]) }

=back

=head2 Error Functions

=over 4

=item error ( )

=item set_error ( STRING [, STRING [, STRING [...]]] )

=item clear_error ( )

Manipulate the ERROR string.  C<error()> and C<clear_error()> should be 
fairly self-explanatory. C<set_error> joins the C<STRING>s it gets, and 
puts them into ERROR.  

=cut

sub set_error { 
  my ($self, @args) = @_;  
  my $error;
  foreach (@args) {  
    chomp;  next unless defined($_); 
    $error ? $error = join(' ', $error, $_)
	   : $error = $_ ; 
  }
  $$self{'ERROR'} = $error;
  $$self{'ERROR'} || undef;
}

sub error { ref $_[0] ? shift->{'ERROR'} || DBI->errstr || undef : $ERROR }
sub clear_error { shift->{'ERROR'} = ""; }

sub _return_error { shift->set_error(@_); undef }

=item add_query ( STRING )

Adds STRING to the query list.  Returns a reference to an array containing
the full set of queries invoked on this object.

=cut

sub add_query {
  my ($self, $query) = @_;
  return undef unless $query;
  push @{$self->{'QUERIES'}}, $query;
  @{$self->{'QUERIES'}};
}

=item clear_queries ()

Clears the query list.

=cut

sub clear_queries { shift->{'QUERIES'} = [] }

=item queries ()

Returns the query list, either in an array context or as a string with
the queries separated by newlines.

=cut

sub queries { wantarray ? @{$_[0]->{'QUERIES'}} : join("\n", $_[0]->{'QUERIES'}) }

=item version ()

Returns the package's version number.

=cut

sub version { $VERSION }

=back

=head2 Database Structure Queries

=over 4

=item tables ( [DATABASE] )

Returns a list of the names of the tables in the current database (or 
C<DATABASE>, if offered).  

=cut

sub tables { 
  my $hash = fieldhash(@_); 
  $hash && ref $hash ? keys %{$hash} : "";
}

=item fields ( [TABLE [, DATABASE]] ) 

Returns the field names for the given C<TABLE>.  If invoked in a scalar 
context, returns a hash reference to the field/datatype pairs from C<TABLE> 
and C<DATABASE>.  In an array context, returns just the field names.  

If C<DATABASE> is not offered, assumes the current database.  If C<TABLE> 
is not offered, returns the same thing as C<fieldhash()>.  Returns undef 
if C<TABLE> is offered but does not exist, or if no information is available.

=cut

sub fields { 
  my ($self, $table, $database) = @_;
  $database ||= $self->_database() || "";
  return $self->fieldhash($database) unless $table;

  my $fieldhash = $self->fieldhash($database);  
  return undef unless $fieldhash && ref $fieldhash;

  my $fields = $$fieldhash{$table};  
  return undef unless $fields && ref $fields;

  return wantarray ? keys %{$fields} : $fields;
}

=item list ( [TABLE [, DATABASE]] )

Returns the 'list' array for the given C<TABLE>.  If invoked in a scalar 
context, returns an array reference to C<TABLE> and C<DATABASE>'s 'list'.
In an array context, returns the whole thing.

If C<DATABASE> is not offered, assumes the current database.  If C<TABLE> 
is not offered, returns the same thing as C<listhash()>.  Returns undef 
if C<TABLE> is offered but does not exist, or if no information is available.

=cut

sub list {
  my ($self, $table, $database) = @_;
  $database ||= $self->_database() || "";
  return $self->listhash($database) unless $table;

  my $listhash = $self->listhash($database);  
  return undef unless $listhash && ref $listhash;

  my $list = $$listhash{$table};  
  return undef unless $list && ref $list;

  return wantarray ? @{$list} : $list;
}

=item key ( [TABLE [, DATABASE]] )

=item keys ( [TABLE [, DATABASE]] )

=item required ( [TABLE [, DATABASE]] )

=item admin ( [TABLE [, DATABASE]] )

=item order ( [TABLE [, DATABASE]] )

These functions return the appropriate array of table fields, as in the
appropriate hash tables.  If invoked in a scalar context, return an array
reference to C<TABLE> and C<DATABASE>'s information (as appropriate).  In
an array context, returns the whole thing as separate items.  

If C<DATABASE> is not offered, assumes the current database.  If C<TABLE>
is not offered, returns the same thing as the appropriate C<xxxxhash()>.
Returns undef if C<TABLE> is offered but does not exist, or if no
information is available.

=cut

sub key      { shift->_generic_list(\&keyhash, @_) }
sub required { shift->_generic_list(\&requiredhash, @_) }
sub admin    { shift->_generic_list(\&adminhash, @_) }
sub order    { shift->_generic_list(\&orderhash, @_) }

sub _generic_list {
  my ($self, $coderef, $table, $database) = @_;
  $database ||= $self->_database || "";
  my $hash = $self->$coderef($database);
  return $hash unless $table;
  return undef unless ($hash && ref $hash);
  
  my $return = $$hash{$table} || return undef;
  return ref $return ? wantarray ? @{$return} : $return
		     : wantarray ? $return : ( $return ) ;
}

=item html ( [TABLE [, DATABASE]] )

=item text ( [TABLE [, DATABASE]] )

Returns the 'html' or 'text' code reference for the given C<TABLE> and
C<DATABASE>, as appropriate.  If C<DATABASE> is not offered, assumes the
current database.  If C<TABLE> is not offered, returns the same thing as
C<xxxxhash()>.  Returns undef if C<TABLE> is offered but does not exist,
or if no information is available.

=cut

sub html { shift->_generic_code(\&htmlhash, @_) }
sub text { shift->_generic_code(\&texthash, @_) }

sub _generic_code {
  my ($self, $coderef, $table, $database) = @_;
  $database ||= $self->_database || "";
  my $hash = $self->$coderef($database);
  return $hash unless $table;	
  return undef unless ($hash && ref $hash);
  
  my $return = $$hash{$table} || return undef;
  $return || undef;
}

=item list_head ( TABLE )

Returns an array of strings that are the headers for a C<make_list()>
command.  Uses LIST for its data.

=cut

sub list_head {
  my ($self, $table) = @_;
  return undef unless $table;

  my @return;

  my @list = $self->list($table);	# Get items out of %LIST
  foreach (@list) { push @return, ref $_ ? join(' ', keys %{$_} ) : $_; }
  wantarray ? @return : join("\n", @return);
}

=item make_list ( TABLE, ITEMHASH [, ITEMHASH [, ITEMHASH [...]]] )

Actually uses the LIST function.  Takes one or more C<ITEMHASH> (the return 
from a C<select()> function, essentially), and makes an array of each item
that belongs on the list.  Returns an array of array references, one for
each C<ITEMHASH> that is offered.

=cut

sub make_list {
  my ($self, $table, @items) = @_;
  return undef unless $table;
  my @list = $self->list($table);	# Get items out of %LIST

  my @return;
  
  # Go through all of the items in @list, replacing them with _replace, 
  foreach my $item (@items) {	
    foreach (@list) {
      push @return, join(' ', $self->_replace( $item, ref $_ ? values %{$_} 
				         : join('', '$$', $_, '$$')) );
    }
  }
  @return;
}

=item keyhash ( [DATABASE] )

=item fieldhash ( [DATABASE] )

=item listhash ( [DATABASE] )

=item requiredhash ( [DATABASE] )

=item orderhash ( [DATABASE] )

=item adminhash ( [DATABASE] )

=item htmlhash ( [DATABASE] )

=item texthash ( [DATABASE] )

Returns the appropriate hash reference to the underlying data in the
DBIx::Frame object.  This takes the structure of:

  Key		  TABLE1, TABLE2, etc

  Value
    fieldhash  	  hash reference - keys are the field names in the 
	          table, values are the data types of those keys
    listhash	  array reference - field names that are for list()
    keyhash	  \ 
    requiredhash   \ array reference - field names that are 'keys', 
    orderhash      / 'required', 'order', or 'admin', as appropriate
    adminhash     /
    htmlhash      code reference - create an HTML table of the data
    texthash      code reference - create a text summary of the data

More information on these is below.

Uses the current database, or C<DATABASE> if offered.

=cut

sub _gethash {
  my ($self, $type, $database) = @_;
  $database ||= $self->_database || "";
  $database ? $$self{$type}->{$database} : $$self{$type};
}

sub fieldhash { shift->_gethash('FIELDS', @_) }
sub keyhash   { shift->_gethash('KEYS',   @_) }
sub adminhash { shift->_gethash('ADMIN',  @_) }
sub listhash  { shift->_gethash('LIST',   @_) }
sub orderhash { shift->_gethash('ORDER',  @_) }
sub htmlhash  { shift->_gethash('HTML',   @_) }
sub texthash  { shift->_gethash('TEXT',   @_) }
sub requiredhash { shift->_gethash('REQUIRED', @_) }

## Has to be slightly different, since we look for KEYS here if there is
## no REQUIRED present.
# sub requiredhash {
#   my ($self, $database) = @_;
#   $database ||= $self->_database || "";
#   $database ? $$self{REQUIRED}->{$database} || $$self{KEYS}->{$database} 
# 	    : $$self{REQUIRED} || $$self{KEYS};
# }

=back

=head2 Helper Functions

=over 4

=item select_fieldlist ( TABLE, FIELD [, DATAHASH [, OTHER ]] )

Using select() with (or without) C<DATAHASH>, returns an array containing
the C<FIELD> field from all matching entries.  B<OTHER> is passed into the
select().  Useful if you just want to select all of the names out of a
Person table, or something similar.

=cut

sub select_fieldlist {
  my ($self, $table, $field, $datahash, @other) = @_;
  return undef unless ($table && $field);
  my @list;
  foreach ( $self->select($table, $datahash || {}, $field, @other) ) {
    push @list, $$_{$field} if ref $_;
  }
  scalar @list ? @list : undef;
}

=item select_fieldlist_id ( TABLE, FIELD [, DATAHASH, [, OTHER ]] )

Does the same thing as B<select_fieldlist()>, except that the entries are
returned as a hash, where the keys are the relevant ID fields.

=cut

# Maybe this should confirm that there is an ID field first?
sub select_fieldlist_id {
  my ($self, $table, $field, $datahash, @other) = @_;
  return undef unless ($table && $field);
  my %hash;
  my $match = "$field, ID";
  foreach my $entry ( $self->select($table, $datahash || {}, $match, @other) ) {
    next unless ref $entry;
    my $id = $$entry{ID};  my $value = $$entry{$field};
    $hash{$id} = $value;
  }
  %hash;
}

=item select_list_id ( TABLE [, DATAHASH [, OTHER ]] )

Using select() with (or without) C<DATAHASH>, returns a hash reference 
containing key/value pairs where the key is the relevant C<ID> and the
values are the results of B<make_list()>.  Useful for getting a human-
parsable version of a select() statement.

=cut

sub select_list_id {
  my ($self, $table, $datahash, @other) = @_;
  return undef unless $table;
  my %hash;
  foreach my $entry ( $self->select($table, $datahash || {}, @other) ) {
    next unless ref $entry;
    my $id = $$entry{ID};
    my $array = [ $self->make_list($table, $entry) ];
    $hash{$id} = $array;
  }
  %hash;
}

=back

=cut

##### INTERNAL FUNCTIONS #####
### _parse_hash ( TABLE, DATAHASH )
# Parses a datahash and returns an updated hash that only contains data 
# for the appropriate table.  Returns undef if there was no appropriate 
# data.
sub _parse_hash {
  my ($self, $table, $hash) = @_;
  return undef unless $table;
  my $db = $self->db || return undef;

  # Parse the hash information
  return undef unless ($hash && ref $hash);

  my %newhash;
  foreach my $key (sort keys %{$hash}) { 
    next unless ( defined $key && defined $$hash{$key} );
    my $shortkey = $key;  $shortkey =~ s/ .*$//;	
    my $type = $self->fields($table)->{$key};
    next unless defined($type);		# Not in the database - bad data
    $newhash{$key} = $type =~ /^\s*int/i ? $$hash{$key} || "''"
					 : $db->quote($$hash{$key});
    $newhash{$key} =~ s%(^\s+|\s+$)%%;	# Lose the leading/trailing whitespace
  }
  
  scalar(keys %newhash) ? \%newhash : undef;
}

### _test_table ( TABLE )
# Makes sure that the table exists in the open database.  Returns 1 if it 
# does, undef otherwise.  
sub _test_table {
  my $self = shift;
  my $db = $self->db || return undef;

  my $table = shift;
  unless ($table) { $self->set_error("No table given");  return undef }

  unless ( grep /^$table$/, $db->func( '_ListTables') ) {
    $self->set_error("Table '$table' doesn't exist");  return undef;
  }

  1;
}

### _make_select ( TABLE, HASH, LIMIT, NOORDER )
# Makes the "WHERE blah=blah and blah2=blah2" part of the SELECT statement,
# based on TABLE and HASH.  Returns undef if nothing is passed in, or "" if 
# there's nothing to select.  LIMIT is another hash reference, and is
# optional; it can be used to add 'ORDER BY' or 'LIMIT' bits.
sub _make_select {
  my ($self, $table, $hash, $limit, $noorder, $other) = @_;
  my $db = $self->db || return undef;
  return undef unless ($table && $hash && ref $hash);
  
  $limit ||= {};	 

  my @list;
  foreach my $key (sort keys %{$hash}) { 
    my $value = $$hash{$key} || "";  next if ($value =~ /^\s*$/);
    my $type = $self->fieldhash->{$table}->{$key}; 
    next unless defined($type);		# Not in the database - bad data
    if (ref $value) {  
      my @newlist;
      foreach my $val (@{$value}) {
        push @newlist, " $key $val " if $val;
      }
      push @list, "( " . join(" AND ", @newlist) . " )" if @newlist;
    } elsif ($type =~ /^\s*int/i) {
      my $option = "=" unless $key =~ /^\d+$/; 
      $value =~ s/^%|%$//g;	# We don't want wildcard matches here
      push (@list, "$key $option $value") if defined($value);
    } else { 
      $value =~ s%(^\s+|\s+$)%% if $other;  # Lose the leading/trailing 
					    # whitespace (usually)
      push (@list, "$key like " . $db->quote( $value ) ) if $value;
    }
  }
  
  my @final;
  push @final, join(" ", "WHERE", join(" AND ", @list)) if scalar @list;

  # Canonicalize the hash; note that all-caps will win.  It'd be better if 
  # the users only knew that all-caps work, though.
  foreach (sort keys %{$limit}) { $$limit{uc($_)} = $$limit{$_}; }

  # Ordering data is now part of the deal
  my $order = _fix_order( $$limit{'ORDER'} || $self->order($table) || "");
  push @final, $order if ($order && !$noorder);

  # Limiting data doesn't work yet, probably.  Maybe later.  Let's at
  # least try, though.
  my $lim = _fix_limit( $$limit{'LIMIT'} || "");
  push @final, $lim if $lim;
  # if ($$limit{'LIMIT'}) { push @final, "LIMIT $$limit{'LIMIT'}" }

  scalar @final ? join(" " , @final) : "";
}

### _fix_order ( ENTRY [, ENTRY [...]])
# Splits on commas or whitespace, and makes an "ORDER BY [...]" bit for a
# SELECT statement.  
sub _fix_order {
  my @hash;
  my $canon = _canon(shift);
  foreach my $item (split /\s+|\s*,\s*/, $canon) {   
    $item =~ m%-(.*)% ? push @hash, "$1 DESC" : push @hash, $item;
  }
  scalar @hash ? join(" ", "ORDER BY ", join(", ", @hash)) : "";
}

### Not currently implemented
sub _fix_limit { ""; }

### _canon ( ITEM )
# Takes an item, returns a scalar of what's in it.  Not complicated, and
# occasionally useful, but there's probably a better way to do this that I
# don't know off the top of my head.
sub _canon {
  my $item = shift;
  if    ( ref($item) eq "ARRAY" )   { join(' ', @$item) }
  elsif ( ref($item) eq "HASH" )    { join(' ', %$item) }
  elsif ( ref($item) eq "" )        { $item }
  else                              { $item }
}


### _make_select ( TABLES, HASH )
# Makes the "WHERE blah=blah and blah2=blah2" part of the SELECT statement,
# based on TABLES (an array reference) and HASH.  Returns undef if nothing 
# is passed in, or "" if there's nothing to select.  Used with select_multi()
sub _make_select_multi {
  my ($self, $tables, $hash, $other) = @_;
  my $db = $self->db || return undef;
  return undef unless ($tables && ref $tables && $hash && ref $hash);

  my %tables; foreach (@{$tables}) { $tables{$_}++ }

  my @list;
  foreach my $key (sort keys %{$hash}) {
    my $value = $$hash{$key} || "";  next if ($value =~ /^\s*$/);
    my ($table, $row) = $key =~ /^([^\.]+)\.([^\.]+)$/;
    next unless ($table && $row && $tables{$table});
    my $type = $self->fieldhash->{$table}->{$row};
    next unless defined($type);         # Not in the database - bad data
    if (ref $value) {
      my @newlist;
      foreach my $val (@{$value}) {
        push @newlist, " $key $val " if $val;
      }
      push @list, "( " . join(" AND ", @newlist) . " )" if @newlist;
    } elsif ($type =~ /^\s*int/i) {
      my $option = "=" unless $key =~ /^\d+$/;
      $value =~ s/^%|%$//g;     # We don't want wildcard matches here
      push (@list, "$key $option $value") if defined($value);
    } else {
      $value =~ s%(^\s+|\s+$)%% if $other;  # Lose the leading/trailing
                                            # whitespace (usually)
      push (@list, "$key like " . $db->quote( $value ) ) if $value;
    }
  }

  scalar(@list) ? "WHERE " . join(' AND ', @list)
                : "";
}

### _database () 
# Returns the canonical database name that we're connected to, which is
# based on the class of $self and *not* $DBNAME.  Returns undef if $self
# is not offered.
sub _database {
  my $self = shift || return undef;
  $self =~ s/=.*$// if (ref $self);
  $self =~ s%.*::%%g;
  return $self;
}

### _replace ( HASH, LINES )
# Replaces '$$item$$' with $hash{item} for all of LINES, each of which is
# a string.  Also replaces code references as appropriate.  Returns the 
# updated LINES.
sub _replace {
  my ( $self, $hash, @lines ) = @_;
  return @lines unless ($hash && ref $hash);
  map { s/\$\$(\w+)\$\$/$$hash{$1} || ""/egx } @lines;
  map { if (ref $_ eq 'ARRAY') {
          my ( $code, @args ) = @{$_};
          $_ = join("", $code->( $self, $self->_replace ( $hash, @args )));
        } else { $_ } } @lines;
  map { $_ = join("", $_->( $self, $hash ) ) if ( ref $_ eq 'CODE' ) } @lines;

  wantarray ? @lines : join("\n", @lines);
}

### _db_or_die 
# Returns the database or sets an error message and returns undef; let us
# simplify a lot of other code
sub _db_or_die {
  my $self = shift;  
  $$self{'DB'} ? return $$self{'DB'} 
	       : $self->set_error("Not connected") && return undef;
}


### DESTROY 
# Auto-invoked when the object is removed from memory.  Disconnects from
#   the database, just to be nice and leave less errors.
sub DESTROY { shift->disconnect; }

1; 
__DATA__	# Here for SelfLoader

=head1 DATABASE DESIGN

Alone, this module isn't all that useful - if you're just wanting to
invoke some random SQL code on your database, you'll find the DBI module
must more useful to you.  The real strength of this module is that it
allows for a standardized method of creating database modules, which can 
then be controlled with standard tools.  And this is really handy for the 
sysadmin of a certain research group that needs to maintain a large number 
of databases, and would rather not rewrite code all the time.

Each DBIx::Frame object contains one or more databases, each of which contains
one or more tables.  They are initialized using add_table on a created
database; generally, this should be taken care of on initialization.  
Usually each table will be its own module. 

Each table has the following information, in order of importance (note
that more functions may be added at the discretion of the designer):

=cut

=over 4	

=item NAME

This is a string that contains the name of the table.  This should be
fairly self-explanatory.  

Example (from TCB::Publications::Papers):
  
  $NAME = "Papers";

Related functions: C<tables()>

=item  FIELDS	

This is a hashref containing the fields contained within the table.  The
hash has field-name/content-type key/value pairs. These fields are assumed to 
be the only ones the table knows of, and extra data will be discarded by
the functions above.  As such, this is vital if you actually want to use
the database.

Example (from TCB::Publications::Papers):
  
  $FIELDS = {

  # Non User-Modified Information
  'ID'          =>  'INT NOT NULL PRIMARY KEY AUTO_INCREMENT',
  'CreatedBy'   =>  'TINYTEXT',    'ModifiedBy'  =>  'TINYTEXT',
  'CreateDate'  =>  'DATE',        'ModifyDate'  =>  'DATE',

  # Basic Information
  'Title'       =>  'TINYTEXT',    'Authors'     =>  'TINYTEXT',
  'CorrAuth'    =>  'TINYTEXT',    'PaperType'   =>  'TINYTEXT',
  'PubDate'     =>  'TINYTEXT',    'Pages' => 'TINYTEXT',

  # Journal Information
  'Journal'     =>  'TINYTEXT',    'JournalVolume'  =>  'TINYTEXT',
  'JournalManNum'  =>  'TINYTEXT',

  # Book information
  'BookTitle'   =>  'TINYTEXT',    'BookEditors' =>  'TINYTEXT',
  'BookPublishers' =>  'TINYTEXT', 'BookYear'   =>   'TINYTEXT',

  # TB Information
  'PubStatus'   =>  'TINYTEXT',    'Copies'      =>  'INT',
  'TBRef'       =>  'INT',         'TBCode'      =>  'TINYTEXT',
  'TechRpt'     =>  'TINYTEXT',    'Notes'       =>  'TEXT',
  'AccountNum'  =>  'TINYTEXT',    'Grant1'      =>  'TINYTEXT',
  'Grant2'      =>  'TINYTEXT',    'Grant3'      =>  'TINYTEXT',
  'PDF'         =>  'TINYTEXT',    'Abstract'    =>  'TEXT',

          };

Note the 'ID' field at top.  Whenever possible, created databases SHOULD
include such a field, to simplify specifying which database entry is being
referred to at any given time.  MySQL makes this easy; other databases
usually have a similar functionality, using slightly different means.

Related functions: C<fields()>, C<fieldhash()>

=item  KEYS

This is an arrayref containing the 'key fields' for each table.  Each entry is
either a single field names, or an array reference that contains several
field names.  Its purpose is to keep track of 'unique' entries - if there
is already an entry with the field(s), the new item will not be inserted
into the database.  Also, each of these fields must be present in order to 
insert the item into the DB.  This is vital if you want to add or update
information in the database.

Example (from TCB::Publications::Papers):

  $KEYS  = [ 'TBRef', 'TBCode' ];

Defaults to 'ID' if not offered.

Related functions: C<key()>, C<keyhash()>

=item  ORDER

This is an arrayref that defines the fields upon which we should order our
select()s on by default.  Sorts in ascending order unless preceeded by '-', 
in which case we'll sort in descending order.  

Example (from TCB::Seminar::Lecture):

  $ORDER = [ '-Date', 'Name' ];

Defaults to 'ID' if not offered.

=item  ADMIN

This is an an arrayref that contains fields that shouldn't be created or
edited by non-administrative users - that is, these fields are somewhat
protected when being worked on by external users.  Note that this should
not (at this point) be considered safe, it's just a matter of convenience.

Example (from TCB::Conference::Register):

  $ADMIN    = [ 'Approved', 'GotMoney' ];

Defaults to an empty array.

Related functions: C<admin()>, C<adminhash()>

=item  REQUIRED 

This is an arrayref that contains fields that must be filled in when an
entry is created - that is, fields that shouldn't be empty.  Unlike the
KEYS information, these fields don't necessarily have to be unique either.

Example (from TCB::Conference::Register):

  $REQUIRED = [ 'LastName', 'FirstName', 'Email', 'Title', 'Institution',
                'Department', 'Housing', 'Gender', 'Citizenship' ];

Defaults to 'ID' or, in most cases, the same as KEYS.

Related functions: C<required()>, C<requiredhash()>, C<key()>

=item  LIST			

This is an array reference containing the elements that should be listed 
off in the case of a C<make_list()> function, and the headers of that list
from a C<list_head()> function.  These are used in quick summaries of the 
database information.  Defaults to every field in the table.  

Each array element can take one of three forms:  

=over 4

=item Scalar

Must be one of the fields of the table.  C<list_head()> will return
the name of the field, and C<make_list()> will return the value of that
field (or "" if empty).

=item Hash Reference 

Must contain only a single key/value pair.  C<list_head()>
will return the key of this pair, and C<make_list()> will return the
interpreted value.  The interpretation is peformed with the following steps:

  - '$$item$$' is replaced with the value of the 'item' field 
    (or "" if empty).  
  - If the value of the pair is an array, the first item is 
    expected to be a code reference, and the later items are 
    arguments to be passed to the code.  The argument set will 
    be ($self, C<ITEMHASH>, ARG1, ARG2, ARG3...)

=item Code Reference

Runs the code, with the argument set being ($self, C<ITEMHASH>).  

=back

Example (from TCB::System::Port): 

  $LIST = [ 
    { 'Room' => '$$RoomNumber$$ $$Building$$' },
    { 'Port Speed' => '$$PortSpeed$$' } ,
    'BoxNumber', 'PortNumber', 'PortMachine' ];

Another example (from TCB::Travel::Event):

  $LIST  = [ 
	'Title', 'Location',
        { 'Dates' => [ \&dates, '$$Start$$', '$$End$$' ] },
        { 'URL'   => [ \&url, '$$URL$$' ] }
           ];

Related functions: C<list()>, C<listref()>, C<list_head()>, C<make_list()> 

=item  HTML

This is a code reference that, when invoked, will return a string
containing a table with form entries to allow the creation of new entries
and the updates of old ones.  This isn't necessary, but is probably worth
your time to create.

The function should take inputs like this:

  $self  - a reference to the DBIx::Frame object
  $entry - a hash reference containing the default data, with the keys
	   being the table fields and the values being their contents.
  $type  - the type of function you're working with, typically one of
	   'create', 'search', 'edit', or 'view'.
  $opts  - a hash reference containing extra flags that are passed on from
	   the script (not the user!) to the subroutine.  These are used 
	   to customize the output of html() based on the invoking script.  
	   Note that this is not documented in the below example!
  @rest  - anything else it feels like taking

The returned HTML can either be a table (which doesn't require any
stylesheet information) or properly formatted HTML4.  If the latter, you
may want to make sure scripts that invoke this function also use a
relevant stylesheet.  

Example (from TCB::Publications::Files):

  sub html {
    my ($self, $entry, $type, $options, @rest) = @_;
    my $cgi = new CGI;    $entry ||= {};
  
    my %public = ( 0 => "Public", 1 => "Internal Only" );
    if (lc $type eq 'search') { $public{''} = "*" }
  
    my @types = sort @LINKTYPES;  unshift @types, '';
  
    my @codes = sort grep { $_ if /\S+/ } 
                  $self->select_fieldlist('Papers', 'TBCode');  
    unshift @codes, '';

  my @return = <<HTML;
  <div class="basetable">
   <div class="row2">
    <span class="label">TBCode</span>
    <span class="formw">
     @{[ $cgi->popup_menu('TBCode', \@codes, $$entry{TBCode} || "") ]} 
    </span>
    <span class="label">File Type</span>
    <span class="formw">
     @{[ $cgi->popup_menu('Type', \@types, $$entry{Type} || "") ]}
    </span>
   </div>
  
   <div class="row1">
    <span class="label">Location</span>
    <span class="formw">
     @{[ $cgi->textfield('Location', $$entry{Location} || "", 70, 1024) ]}
    </span>
   </div>
  
   <div class="row1">
    <span class="label">Description</span>
    <span class="formw">
       @{[ $cgi->textarea(-name=>'Description', 
                          -default=>$$entry{Description} || "",
                          -rows=>7, -cols=>60, -maxlength=>65535,
                          -wrap=>'physical') ]}
    </span>
   </div>
  
   <div class="row1">
    <span class="label">Restricted?</span>
    <span class="formw">
      @{[ $cgi->popup_menu('Restricted', [sort keys %public], 
                    $$entry{Restricted} || "", \%public) ]}
    </span>
   </div>
  
  
   <div class="submitbar"> @{[ $cgi->submit(-name=>"Submit") ]} </div>
  
  </div>
  
  HTML
    wantarray ? @return : join("\n", @return);
  }

Related functions: C<html()>, C<htmlref()>

=item  TEXT

This is a code reference that, when invoked, will return a string
containing the data that you wish to display in text.  This mostly 
pertains to C<DBIx::Frame::Text>.  

Example (from TCB::mysql::user):

  sub text {
  my ($self, $entry) = @_;
  return sprintf(
	"%22s %22s %22s %1s%1s%1s%1s%1s%1s%1s%1s%1s%1s",
        $$entry{Host}, $$entry{User}, $$entry{Password}, 
	$$entry{Select_priv}, $$entry{Insert_priv}, 
	$$entry{Delete_priv}, $$entry{Create_priv},
        $$entry{Drop_priv}, $$entry{Grant_priv}, 
	$$entry{References_priv}, $$entry{Index_priv}, 
	$$entry{Alter_priv} );
}

Related functions: C<text()>, C<textref()>

=back

=head1 NOTES

This module was designed for use with MySQL, and hasn't been tested with
anything else.  Most things should be portable, however, probably with
little effort; only some internal code may need changing.  

=head1 REQUIREMENTS

Perl 5 or better, the DBI module, and the appropriate drivers for your
database (DBD::mysql, in our case).  To really make it useful you'll want 
a set of DBIx::Frame database modules, such as C<TCB::AddressBook> or
C<TCB::Publications>, though you can (and should) design your own.

=head1 SEE ALSO

B<DBI>, B<DBIx::Frame::CGI>.  Many of the databases on the MDTools web
site (B<http://www.ks.uiuc.edu/Development/MDTools/>) offer further
examples of how to design databases and use this package.

=head1 TODO

Make this less dependent on MySQL.  This should happen naturally, since
I'm planning on trying out Oracle next. 

Should make something to require unique KEYs into the 'update' command
also.  This is fairly tricky.

Create and release DBIx::Frame::Text, to further simplify using these 
tools from the command-line or the web.

Make some functions to change the database's layout on-the-fly, or at
least in a few simple steps (easier said than done).

Make some scripts to auto-generate modules to specification.

=head1 AUTHOR

Written by Tim Skirvin <tskirvin@ks.uiuc.edu>.

=head1 HOMEPAGE

B<http://www.ks.uiuc.edu/Development/MDTools/dbixframe/>

=head1 LICENSE

This code is distributed under the University of Illinois Open Source
License.  See
C<http://www.ks.uiuc.edu/Development/MDTools/dbixframe/license.html> for
details.

=head1 COPYRIGHT

Copyright 2000-2004 by the University of Illinois Board of Trustees and
Tim Skirvin <tskirvin@ks.uiuc.edu>.

=cut

###############################################################################
##### Version History #########################################################
###############################################################################
# v0.9	 (sometime in late 2000)
### First version with a real amount of documentation.  It's been running
### our databases for the last few months, though, so I know it works well.

# v0.99  	Thu Mar 22 13:36:29 CST 2001
### Just about ready for a real release.  Documentation is good, the API (of 
### sorts) is ready to go, and our internal modules are ready for the slight 
### modifications necessary from the changes.  We still need to work out
### licensing issues, make TB::Test, and make a test suite, but this
### module is pretty much good to go.  Renamed it to DBI::Frame, while I
### was at it.

# v0.991 	Fri Mar 23 13:29:57 CST 2001
### Changed 'insert' to actually check for duplicate entries, and updated
### _make_select() so it would work properly.

# v0.992 	Thu Jun  7 09:00:58 CDT 2001
### Fixed htmlhash, texthash, etc so that they'd use their local information
### instead of the system-wide info.  Added 'DBNAME', to allow modules to
### use a canonical name for the database while using a different name for 
### the actual DB.

# v0.993 	Wed Jul 11 16:21:51 CDT 2001
### Fixed add_table to use DBNAME appropriately and correctly.

# v0.999 	Fri Jul 13 11:26:20 CDT 2001
### Finished DBI::Frame::CGI, and added references to it here.

# v1.0 	Tue Aug 21 16:04:19 CDT 2001
### Gave up on the licensing issue.  Added a dummy actions() function.

# v1.01 	Thu Sep  6 13:06:56 CDT 2001
### Slight change in tables(), returns a null string instead of 'undef'.
### Set better defaults for init().

# v1.02 	Thu Feb 21 11:16:09 CST 2002
### Changed to UIUC/NCSA Open Source License - essentially the BSD license.

# v1.03.02 	Fri Mar 22 13:35:49 CST 2002
### Took DBNAME out of _database(), so the name is actually canonical.
### Fixed add_table to match _database(). Took action() out of DBI::Frame to
### avoid a warning.

# v1.03.03 	Tue Apr  2 11:02:18 CST 2002
### Updated _replace() to work right, documented its full behaviour.
### Added the Helper Functions list of functions - select_fieldlist(), 
### select_fieldlist_id(), and select_list_id().  

# v1.03.04 	Fri Apr  5 14:49:28 CST 2002
### Added select_multi and _make_select_multi().

# v1.03.05 	Tue Jun 18 13:00:28 CDT 2002
### Split off set_html(), set_list(), etc.  

# v1.04		Wed Aug 14 16:37:59 CDT 2002
### Updated to match the current version.

# v1.05		Tue Oct  8 10:19:22 CDT 2002
### Added documentation about the 'options' hashref in html().
# v1.05.01	Thu Jan 16 13:34:21 CST 2003
### Updated license to indicate that we're now the TCBG instead of the TBG.
### Updated how select() does its work.  
### Added new fields to every table - REQUIRED, ADMIN, and ORDER.  All
###   of them are essentially optional.  Added set_table(), which will
###   replace add_table() for compatibility reasons, to use these fields.
###   There are also set_required(), set_admin(), set_order(), required(), 
###   admin(), and order() functions.
### Updated how select() works - if the old MATCH entry is a hash, then
###   we'll assume there's lots of data in there and use it.  This lets us 
###   do more sophisticated queries and, most importantly, use the ORDER
###   stuff.  
### Updated _make_select() as well to use the old MATCH entry.
### Using _gethash() to simplify the entire series of xxxxhash() functions.
### Still need to document all of this.
### Still need to update _make_select_multi().
### Still need to build in LIMIT things
# v1.05.02	Fri Jan 17 11:43:34 CST 2003
### Replacing the set_ functions with calls to _set(), created _set()
### Using SelfLoader to speed load times.
### More data abstraction, especially with _db_or_die().
### General code modifications
### Documented all of the major changes.
# v1.05.03 	Mon Jan 27 16:41:33 CST 2003
### Fixed how REQUIRED works.  I think.
# v1.05.04	Wed Feb  5 08:42:35 CST 2003
### delete() now removes everything after ORDER BY from the select
### statement
# v1.05.05	Mon Mar 24 12:58:41 CST 2003 
### Fixed update() and delete() to use _make_select() properly.  Updated
###   _make_select() to not return the ORDER BY bit if it's not necessary.
# v1.05.06	Thu Mar 27 14:18:10 CST 2003 
### Trying to work on this don't-order thing some more.  
# v1.05.07	Tue Oct 21 13:33:56 CDT 2003 
### Renamed to DBIx::Frame.  Getting ready for a release.
# v1.06		Wed May 26 09:24:06 CDT 2004 
### Lots of documentation updates.
