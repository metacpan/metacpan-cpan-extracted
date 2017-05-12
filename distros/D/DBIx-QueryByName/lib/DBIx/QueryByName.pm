package DBIx::QueryByName;
use utf8;
use strict;
use warnings;
use DBI;
use Carp qw(cluck);
use XML::Parser;
use XML::SimpleObject;
use Data::Dumper;
use DBIx::QueryByName::Logger qw(get_logger debug);
use DBIx::QueryByName::QueryPool;
use DBIx::QueryByName::DbhPool;
use DBIx::QueryByName::SthPool;
use DBIx::QueryByName::FromXML;
use DBIx::QueryByName::Result::HashIterator;
use DBIx::QueryByName::Result::ScalarIterator;

use accessors::chained qw(_query_pool _dbh_pool _sth_pool);

our $VERSION = '0.18';

our $AUTOLOAD;

# TODO: add ->dbh($session_name) and remove query, quote, begin_work,
# TODO: rollback and commit?

# Return an instance of self
sub new {
    my $self = bless( {}, $_[0] );

    $self->_dbh_pool(   new DBIx::QueryByName::DbhPool($self) );
    $self->_sth_pool(   new DBIx::QueryByName::SthPool($self) );
    $self->_query_pool( new DBIx::QueryByName::QueryPool()    );

    # Unfortunately, we are forced to have circular references, in
    # order to get DESTROY to work in the proper order.
    $self->_sth_pool->parent($self);
    $self->_dbh_pool->parent($self);

    return $self;
}

# Start a transaction on the session's connection
sub begin_work {
    my ($self,$session) = @_;
	my $log = get_logger();
    $log->logcroak("undefined session argument in begin_work") if (!defined $session);
    return $self->_dbh_pool()->connect($session)->begin_work;
}

# Rollback on the session's connection
sub rollback {
    my ($self,$session) = @_;
	my $log = get_logger();
    $log->logcroak("undefined session argument in rollback") if (!defined $session);
    return $self->_dbh_pool()->connect($session)->rollback;
}

# Commit on the session's connection
sub commit {
    my ($self,$session) = @_;
	my $log = get_logger();
    $log->logcroak("undefined session argument in commit") if (!defined $session);
    return $self->_dbh_pool()->connect($session)->commit;
}

# Store information on how to open a database session
sub connect {
    my ($self,$session,@params) = @_;
    my $log = get_logger();
    $log->logcroak("undefined session argument in connect") if (!defined $session);
    $self->_dbh_pool()->add_credentials($session,@params);
    return $self;
}

# Call dbi's quote()
sub quote {
    my ($self,$session,$str) = @_;
    my $log = get_logger();

    $log->logcroak("undefined session argument in quote") if (!defined $session);
    $log->logcroak("undefined string argument in quote")  if (!defined $str);

    return $self->_dbh_pool()->connect($session)->quote($str);
}

# Execute a sql query directly
sub query {
    my ($self,$session,$sql) = @_;
    my $log = get_logger();

    $log->logcroak("undefined session argument in query")    if (!defined $session);
    $log->logcroak("undefined sql string argument in query") if (!defined $sql);

    # TODO: shouldn't we get arguments here? @_ passed to execute()?
    my $sth = $self->_dbh_pool()->connect($session)->prepare($sql);
    $sth->execute() or $log->logcroak("Query $sql failed, Error string " . $sth->errstr . "\nTrace: ".cluck);
    return $sth;
}

# Load from a xml file the description of sql queries to proxy
sub load {
    my ($self, %args) = @_;
    my $log = get_logger();
    my $session = delete $args{session} || $log->logcroak("undefined session name in load()");

    if (exists $args{from_xml_file}) {
        my $file = delete $args{from_xml_file};
        $log->logcroak("undefined xml file")    if (!defined $file);
        $log->logcroak("no such file: [$file]") if (! -f $file);

        open FP, "< $file" or $log->logcroak("failed to open [$file]: $!");
        my $xml = do { local $/; <FP> };
        close FP;

        DBIx::QueryByName::FromXML::load( $self->_query_pool, $session, $xml );

    } elsif (exists $args{from_xml}) {
        my $xml = delete $args{from_xml};
        DBIx::QueryByName::FromXML::load( $self->_query_pool, $session, $xml );

    } elsif (exists $args{from_postgres}) {
        delete $args{from_postgres};
        $log->logcroak('not implemented yet');

    } else {
        $log->logcroak('unknown or undefined load source');
    }

    $log->logcroak('unexpected arguments:'.Dumper(%args))
        if (scalar keys %args);

    return $self;
}

# unload all queries loaded under a given session
sub unload {
    my ($self, %args) = @_;
    my $session = delete $args{session} ||
        get_logger()->logcroak("undefined session name in load()");

    $self->_query_pool->delete_queries($session);
    $self->_sth_pool->finish_all_sths();

    return $self;
}

# check if this method is supported
sub can {
    my ($self,$query) = @_;
    get_logger()->logcroak("undefined query name")
        unless defined $query;
    return $self->_query_pool->knows_query($query);
}

sub params {
    my ($self, $query) = @_;

    get_logger()->logcroak("undefined query name")
        unless defined $query;

    if ($self->can($query)) {
        my (undef, undef, undef, @params) = $self->_query_pool->get_query($query);
        return @params;
    }

    return;
}

# Intercept method calls and execute the corresponding loaded query
# TODO: let autoload handle commit/begin_work/rollback/quote?
sub AUTOLOAD {
    my $self   = shift;
    my @values = @_;
    my $log    = get_logger();
    my $sths   = $self->_sth_pool;
    my($query) = $AUTOLOAD;

    return if ($query =~ /DESTROY$/);

    # Do we know this query name?
    $query =~ s!^.*::([^:]+)$!$1!;
    $log->logcroak("unknown database query name ($query)")
        if (!$self->_query_pool->knows_query($query));

    # Transform parameters from a list of hashes into an array (if execute)
    # or an array of arrays (if execute_array)

    my (undef,undef,$result,@paramnames) = $self->_query_pool->get_query($query);

    # If no bulk execution (the usual case), format parameters for execute()
    my @args;
    my $bulk_insertion = (scalar @values > 1) ? 1 : 0;
    if (!$bulk_insertion) {

        debug "Preparing arguments for execute()";
        my $v = shift @values || {};

        $log->logcroak("$query expects a list of hash refs as parameters. Params are: ".Dumper(\@values))
            if (ref $v ne 'HASH');

        foreach my $pname (@paramnames) {
            _validate_param($pname,$v);
            push @args, $v->{$pname};
        }
    } else {
        # Else: bulk insertion. Process many hash of values at once with execute_array()
        debug "Preparing arguments for execute_array()";
        foreach my $pname (@paramnames) {
            my @col;
            foreach my $v (@values) {
                $log->logcroak("$query expects a list of hash refs as parameters. Params are: ".Dumper(\@values))
                    if (ref $v ne 'HASH');
                _validate_param($pname,$v);
                push @col, $v->{$pname};
            }
            push @args, \@col;
        }
    }
    debug "Arguments:" . Dumper(\@args);

    # execute query and return the proper result type
    my $sth = $sths->prepare_and_execute(
        query_name     => $query,
        query_args     => \@args,
        bulk_insertion => $bulk_insertion
    );

    return $sth if ($result eq 'sth');

    my $iterator;
    if ($result =~ /^hashref/) {
        debug "wrapping sth in a Result::HashIterator";
        $iterator = new DBIx::QueryByName::Result::HashIterator($query, $sth);
    } elsif ($result =~ /^scalar/) {
        debug "wrapping sth in a Result::ScalarIterator";
        $iterator = new DBIx::QueryByName::Result::ScalarIterator($query, $sth);
    } else {
        $log->logcroak("BUG: invalid query result type");
    }

    return $iterator if ($result =~ /iterator$/);

    # get the iterator's first entry, test that it's the only one
    debug "fetching the iterator's first result row and returning it";
    my $entry = $iterator->next();

    $log->logcroak("ERROR: query $query returned more than one row. Params are: ".Dumper(\@values))
        if (defined $iterator->next());

    return $entry;
}

sub _validate_param {
    my ($pname,$v) = @_;
    my $log    = get_logger();
    $log->logcroak("parameter $pname is missing from argument hash:\n".Dumper($v))
        if (!exists $v->{$pname});
    $log->logcroak("expected a scalar value for parameter $pname but got: ".Dumper($v))
        if (defined $v->{$pname} && !(ref $v->{$pname} eq '' || ref $v->{$pname} eq 'ARRAY'));
}

1;

__END__

=head1 NAME

DBIx::QueryByName - Execute SQL queries by name

=head1 DESCRIPTION

DBIx::QueryByName allows you to decouple SQL code from Perl code
by replacing inline SQL queries with method calls.

The idea is to write the code of your SQL queries somewhere else than
in your perl code (in a XML file for example) and let
DBIx::QueryByName load those SQL declarations and generate methods to
execute each query as a usual object method call.

As sugar on your code, DBIx::QueryByName let you choose to get the
queries's results as plain DBI statement handles, as single row
results or as various iterator-like objects.

This module also implements automatic database session recovery and
query retry, when it is deemed safe to do so. It was specifically
designed to be used as a high availability interface against a cluster
of replicated postgres databases running behind one service IP.

DBIx::QueryByName can manage multiple database connections and is fork
safe.

=head1 SYNOPSIS

    use DBIx::QueryByName;

    my $dbh = DBIx::QueryByName->new();

    # define 2 database connections
    $dbh->connect("db1", "dbi:Pg:dbname=mydb;host=127.0.0.1;port=6666", $username, $password);
    $dbh->connect("db2", "dbi:SQLite:/path/to/db/file");

    # load some default queries to run against db1
    my $queries = <<__ENDQ__;
    <queries>
        <query name="add_job" params="id,username,description">INSERT INTO jobs (id, username, description, status) VALUES (?,?,?,0)</query>
        <query name="get_job_count" params="" result="scalar">SELECT COUNT(*) FROM jobs</query>
    </queries>
    __ENDQ__

    $dbh->load(session => 'db1', from_xml => $queries);

    # load some default queries to run against db2, from an xml file
    $dbh->load(session => 'db1', from_xml_file => $filepath);

    # now run some queries:

    # insert a few rows in db1.jobs
    $dbh->add_job( { id => 12,
                     username => "tom",
                     description => "catch mouse" } );
    $dbh->add_job( { id => 13,
                     username => "jerry",
                     description => "run away from cat" } );

    # count the number of rows:
    my $count = $dbh->get_job_count();

    # then do what you usually do with a statement handler...

=head1 SESSION MANAGEMENT AND FORK SAFETY

DBIx::QueryByName opens one database connection for every process that
needs to execute a query over a given session (as declared in
C<load()>) and for every child process of that process.

A rollback or commit (or any other database method) therefore only
affects the connection associated with the running process (defined by
its pid C<$$>) and not the connections to the same database openened
for the process's children or parents.

Notice that fork safety has been tested against Postgres databases
only. We cannot guarantee that it works with other databases :)

=head1 AUTOMATED RECOVERY

If a database connection gets interupted or closed, and the reason for
the interuption is that the database server is closing down or is not
reachable, DBIx::QueryByName will transparently try to reconnect to
the database until it succeeds and re-execute the query. Note that
this only works when you call a query by its name. Calls to C<query>,
C<begin_work>, C<commit>, C<rollback> are only aliases to the
corresponding DBI calls and will fail in the same way.

Any other connection or execution failure will still result in a
die/croak that you will have to catch and handle from within your
application.

You may change this default behavior per query by setting the C<retry>
attribute in the query's xml definition (See 'XML SYNTAX').

=head1 SUPPORTED DATABASES

DBIx::QueryByName has been tested thoroughly against postgres. We
cannot guarrantee that it will work with other databases (but it
should :). A database is supported if it provides standard error
messages (see QueryByName.pm::AUTOLOAD) and support the DBI parameter
InactiveDestroy.

=head1 LOGGING

DBIx::QueryByName logs via Log::Log4perl if it is available. If
Log::Log4perl is available but not configured, you may see warnings
poping up. Just configure a default logger in Log::Log4perl to get rid
of them.

=head1 QUERY RESULTS

The result of a named query will be one of the following:

=over 4

=item * a DBI statement handle

=item * a scalar containing the fetched value

=item * a reference to a hash containing the fetched row

=item * an iterator object that returns scalars

=item * an iterator object that returns hashrefs

=back

The type of result a query should return is defined by the xml attribute 'result'
in the named query's xml definition.

=head2 Result as a sth

By default, if the 'result' attribute is not set or set to C<sth>, a
DBI statement handle is returned, on which you may call C<fetchrow*>
or any other standard DBI method.

Example:

    # assuming the xml definition:
    # <query name="get_bcd" params="a" result="sth">SELECT b,c,d FROM jobs WHERE a=?</query>

    my $sth = $dbh->get_bcd({ a => 'this'});
    while (my $v = $sth->fetchrow_hashref) {
        # do stuff with $v
    }

=head2 Result as a hashref

If the 'result' attribute is set to C<hashref>, the query gets
executed and fetchrow_hashref is called on it. IMPORTANT: the query is
expected to return only one row. If multiple rows may be returned, an
error occurs. The matching row is returned as a hash reference. The
previous example then becomes:

Example:

    # assuming the xml definition:
    # <query name="get_bcd" params="a" result="hashref">SELECT b,c,d FROM jobs WHERE a=?</query>

    my $v = $dbh->get_bcd({ a => 'this'});

    # NOTE: an error occurs if get_bcd would return more than 1 row

=head2 Result as a hashref iterator

If the 'result' attribute is set to C<hashrefiterator>, the query gets
executed and an iterator object is returned that supports the method
C<next>. C<next> returns the next fetched row as a hashref or undef if
no more rows are available. The previous example then becomes:

Example:

    # assuming the xml definition:
    # <query name="get_bcd" params="a" result="hashrefiterator">SELECT b,c,d FROM jobs WHERE a=?</query>

    my $it = $dbh->get_bcd({ a => 'this'});
    while (my $v = $it->next) {
        # do stuff with $v
    }

    # alternatively, tell next() to return hash values as a list:
    while ( my ($id,$name) = $it->next('id','name') ) {
        last if (!defined $id);
        ...
    }

For more details on how to use hashref iterators, read the pod of
DBIx::QueryByName::Result::HashIterator.

=head2 Result as a scalar

If the 'result' attribute is set to C<scalar>, the query gets executed
and fetchrow_array is called on it. IMPORTANT: the query is expected
to return only one row and this row should have only one
column. Anything else triggers an error. Otherwise, it returns the
columns value as a scalar.  Usefull for queries like 'SELECT COUNT(*)
FROM...'.

Example:

    # assuming the xml definition:
    # <query name="get_max_id" params="user" result="scalar">SELECT MAX(id) FROM jobs WHERE user=?</query>

    my $max = $dbh->get_max_id({ user => 'me'});

=head2 Result as a scalar iterator

Finally, if the 'result' attribute is set to C<scalariterator>, an
iterator object is returned. It has the same api than for
C<hashrefiterator>, meaning it implements the C<next> method. An error
occurs if the returned rows have more than one column.

Example:

    # assuming the xml definition:
    # <query name="get_job_id" params="a" result="scalariterator">SELECT id FROM jobs WHERE user=?</query>

    # list all the jobs of user 'me'
    my $it = $dbh->get_job_id({ user => 'me'});
    while (my $id = $it->next) {
        # do stuff with the scalar $id
    }

For more details on how to use scalar iterators, read the pod of
DBIx::QueryByName::Result::ScalarIterator.

=head1 INTERFACE

=over 4

=item C<< $dbh = DBIx::QueryByName->new(); >>

Return an instance of DBIx::QueryByName.

=item C<< $dbh->connect($session_name, @dbi_connection_params); >>

Declare how to open (later on) a database connection called
C<$session_name> with the provided standard DBI connection
parameters. Actually opening the connection is defered until needed,
that is until one of query(), quote(), begin_work(), rollback() or
commit() is called or any of the named queries loaded for this
session.

Example:
    $dbh->connect('db',"dbi:Pg:dbname=$db;host=$host;port=$port", $username, $password, {pg_enable_utf8 => 1});

=item C<< $dbh->load(session => $session_name, from_xml_file => $file) >>

or

=item C<< $dbh->load(session => $session_name, from_xml => $string) >>

Load SQL queries from the xml query file C<$queryfile> or the string
C<$string>. Afterward, to execute those queries just call the method
of the same name on C<$dbh>. This method will automatically execute
the corresponding query over the database connection C<$session_name>.
Return C<$dbh>.

=item C<< $dbh->unload(session => $session_name) >>

Unload all the queries previously loaded under the session
C<$session_name>. This let's you implement a reload mechanism in which
you would call C<unload> followed by a number of calls to C<load>.
Return C<$dbh>.

=item C<< my $res = $dbh->$your_query_name( ) >>

or

=item C<< my $res = $dbh->$your_query_name( {param1 => value1, param2 => value2...} ) >>

or

=item C<< my $res = $dbh->$your_query_name( \%values1, \%values2, \%values3... ) >>

Once you have specified how to connect to the database with
C<connect()> and loaded some named queries with C<load()>, you can
execute any of the sql queries by its name as a method of C<$dbh>.

Both single execution and bulk execution are supported.

If the query has no sql parameters, just call the query's method without
parameters. Example:

    $dbh->increase_counter( );

If the query accept a values to bind to sql parameters, pass those
values as an anonymous hash in which keys are the names of sql
parameters and values are their values. Example:

    $dbh->add_book( { author => 'me',
                      title => 'my life',
                      isbn => $blabla,
                    } );

If the query allows it, you may perform bulk execution and
execute multiple parameter hashes at once. This is done by
calling DBI's execute_array method. Example:

    # insert 2 books at once (or more)
    $dbh->add_book( { author => 'me',
                      title => 'my life',
                      isbn => $blabla,
                    },
                    { author => 'you',
                      title => 'your life',
                      isbn => $moreblabla,
                    },
                  );

For a detailed description of what the named query returns, refer
to the section 'QUERY RESULTS'.

=item C<< my $bool = $dbh->can($query_name) >>

Return 1 if the query C<$query_name> is implemented, 0 if not.

=item C<< my @params = $dbh->params($query_name) >>

Return the named parameters expected by the query C<$query_name>.

=back

The following methods are just aliases for the corresponding DBI
methods. Do not use them if you don't really have to as some might be
removed in a later version of this module.

=over 4

=item C<< $dbh->rollback($session_name); >>

Perform a rollback on the session named C<$session_name> and return
its result.

=item C<< $dbh->commit(); >>

Perform a commit on the session named C<$session_name> and return its
result.

=item C<< $dbh->begin_work(); >>

Call the DBI begin_work() method on the session named
C<$session_name> and return its result.

=item C<< $dbh->quote($session_name, $string); >>

Call DBI's quote() method on C<$string> for the database handler
associated with C<$session_name> and return its result. WARNING: this
method might be removed from later versions as it is outside the core
scope of this module. Use at your own risk.

=item C<< my $sth = $dbh->query($session_name,$sql); >>

Call prepare and execute for this SQL. Return the executed statement
handler. WARNING: this method might be removed from later versions as
it only provides a backdoor to the querying-by-name mechanism. Use at
your own risk.

=back

=head1 XML SYNTAX

When calling load() with C<from_xml> or C<from_xml_file>, the XML
string expected must have the following format:

    <queries>
        <query name="{query's name}"
               params="{names of the sql's placeholders, as a comma-separated and in order of appearance}"
               result="one of (sth|scalar|scalariterator|hashref|hashrefiterator)"
               retry="one of (safe|always|never)">
        {some sql code with placeholders}</query>
        <query ...>...</query>
        <query ...>...</query>
        <query ...>...</query>
        ...
    </queries>

Always use placeholders ('?' signs) in your SQL!

The C<result> tag specifies what kind of object the named query should return.

The C<retry> attribute is optional and tells DBIx::QueryByName how to
behave upon getting a timeout error from the server. If C<retry> is
set to 'never', the query will never be retried if it fails. If
C<retry> is set to 'safe', the query will be retried only if it failed
with an error message that guarrantees that the query was not executed
by the server. If C<retry> is set to 'always' and the error message is
a known one (see SthPool.pm), the query gets retried. Note that this
feature recognizes only a restricted subset of server error messages,
and does not support servers other than postgres. If C<retry> is
omitted, it defaults to 'safe'.

=head1 DEBUGGING

To see all the gutwork happening on stderr, set the environment
variable DBIXQUERYBYNAMEDEBUG to 1.

=head1 KNOWN ISSUES

=head2 Forked processes not calling queries

If a process opens one or more database connections and forks, but
it's child opens no database connection of its own, the connections of
the parent will be closed without respect to InactiveDestroy when the
child exits. To avoid troubles, always commit data explicitely.

=head2 Execute does not timeout

In some cases, a call to DBI's execute method (or ping) may hang
forever. This may happen if you loose contact with the server during
an operation. DBIx::QueryByName does no attempt at making execute to
timeout. This is a design decision.

The only alternative would be to implement a eval/die/alarm block
around the execute call but that would require to run perl with
unsafe signal handling, which the authors declined to do.

For an example of how to implement such an eval/die/alarm block,
see the source for SthPool.pm.

=head1 SEE ALSO

DBIx::NamedQuery: almost the same but doesn't support named
parameters, forks and multiple simultaneous database connections.

=head1 AUTHORS

Created by Joel Jacobson <joel AT gluefinance.com>.

Maintained by Erwan Lemonnier <erwan AT gluefinance.com> with the support of Claes Jakobsson <claes AT gluefinance.com>.

=head1 COPYRIGHT AND DISCLAIMER

This module was developed by Glue Finance AB as part of the
corporation's software development activities. This module is
distributed under the same terms as Perl itself. We encourage you to
help us improving this module by sending feedback and bug reports to
the maintainer(s).

This module is provided 'as is' and comes with no warranty. Glue
Finance AB as well as the author(s) decline any responsibility for the
consequences of using all or part of this module.

Glue Finance is a payment solution provider based in Stockholm,
Sweden. Our clients include online and offline companies requiring low
cost instant payment transfers domestically and internationally. For
more information, please see our website.

=head1 SVN INFO

$Id$

=cut
