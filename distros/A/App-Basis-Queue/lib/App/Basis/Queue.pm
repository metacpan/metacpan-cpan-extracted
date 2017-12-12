# ABSTRACT: Simple database backed FIFO queues

# SELECT counter, queue_name, added, activates, expires,data
# FROM qsdb_queue
# WHERE queue_name LIKE '%'
#   AND processed = 0
#   AND process_failure = 0
#   ORDER BY activates ASC, counter ASC
# ;


=head1 NAME

App::Basis::Queue

=head1 SYNOPSIS

    use App::Basis::Queue;

    my $dsn = "dbi:SQLite:/location/of/sqlite_db.sqlite3" ;
    my $dbh = DBI->connect( $dsn, "", "",
        { RaiseError => 1, PrintError => 0, } )
        or die "Could not connect to DB $dsn" ;

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

    # save some application audit data for later processing
    $queue->add(
        queue => '/invoice/pay',
        data => {
            ip => 12.12.12.12,
            session_id => 12324324345,
            client_id => 248296432984,
            amount => 250.45,
            reply => '/payments/made'
            },
    ) ;

    # in another process, we want to process that data

    use App::Basis::Queue;

    # for the example this will be paying an invoice
    sub processing_callback {
        my ( $queue, $qname, $record, $params ) = @_;

        # call the payment system
        # pay_money( $params->{auth}, $record->{client_id}, $record->{amount}) ;

        # chatter back that the payment has been made, assume it worked
        $queue->pub( queue => $record->{reply},
            data => {
            client_id => $record->{ client_id},
            success => 1,
            }
        ) ;
    }

    my $dsn = "dbi:SQLite:/location/of/sqlite_db.sqlite3" ;
    my $dbh = DBI->connect( $dsn, "", "",
        { RaiseError => 1, PrintError => 0, } )
        or die "Could not connect to DB $dsn" ;
    my $queue = App::Basis::Queue->new( dbh => $dbh) ;
    $queue->process(
         queue => 'app_start',
         count => 10,
         callback => \&processing_callback,
         callback_params => { auth => 'sometoken:12345'}
    ) ;

    # for pubsub we do

    use App::Basis::Queue;

    my $dsn = "dbi:SQLite:/location/of/sqlite_db.sqlite3" ;
    my $dbh = DBI->connect( $dsn, "", "",
        { RaiseError => 1, PrintError => 0, } )
        or die "Could not connect to DB $dsn" ;
    my $queue = App::Basis::Queue->new( dbh => $dbh) ;
    # for a system that wants to know when servers have started
    $queue->publish( queue => '/chat/helo', data => { host => 'abc, msg => 'helo world') ;

    # in another process

    use App::Basis::Queue;
        my $dsn = "dbi:SQLite:/location/of/sqlite_db.sqlite3" ;
    my $dbh = DBI->connect( $dsn, "", "",
        { RaiseError => 1, PrintError => 0, } )
        or die "Could not connect to DB $dsn" ;
    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

=head1 DESCRIPTION

Why have another queuing system? Well for me I wanted a queuing system that did not mean
I needed to install and maintain another server (ie RabbitMQ). Something that could run
against existing DBs (eg PostgreSQL). PGQ was an option, but as it throws away queued items
if there is not a listener, then this was useless! Some of the Job/Worker systems required you to create
classes and plugins to process the queue. Queue::DBI almost made the grade but only has one queue. Minon
maybe could do what was needed but I did not find it in time.

I need multiple queues plus new requirement queue wildcards!

So I created this simple/basic system. You need to expire items, clean the queue and do things like that by hand,
there is no automation. You process items in the queue in chunks, not via a nice iterator.

There is no queue polling per se you need to process the queue and try again when all are done,
there can only be one consumer of a record which is a good thing, if you cannot process an item it can be marked as
failed to be handled by a cleanup function you will need to create.

=head1 End of Life

I created this project mostly as a learning project, my requirements for what it does are changing which will
involve client/server operations, a shared cache and locking system for the task clients, so I am going to leave this
project parked and start something new

=head1 AUTHOR

kmulholland, moodfarm@cpan.org

=head1 See Also

L<Queue::DBI>, L<AnyMQ::Queue>, L<Minion>

=head1 API

=cut

package App::Basis::Queue ;
$App::Basis::Queue::VERSION = '000.600.100';
use 5.10.0 ;
use feature 'state' ;
use strict ;
use warnings ;
use Moo ;
use MooX::Types::MooseLike::Base qw/InstanceOf HashRef Str/ ;
use JSON ;
use Data::UUID ;
use Try::Tiny ;
use POSIX qw( strftime) ;
use Time::HiRes qw(gettimeofday tv_interval ) ;
use Date::Manip ;

# use Data::Printer ;

# extends "App::Basis::QueueBase" ;

# -----------------------------------------------------------------------------

use constant MSG_TASK            => 'task' ;
use constant MSG_CHATTER         => 'chatter' ;
use constant MSG_SIMPLE          => 'simple' ;
use constant MAX_PROCESS_ITEMS   => 100 ;
use constant FIVE_DAYS           => 5 * 24 * 3600 ;
use constant MAX_EXPIRY_DATETIME => "3000-01-01 12:00 UTC" ;
use constant PEEK_MAX           => 100 ;

# -----------------------------------------------------------------------------
## class initialisation
## instancation variables
# -----------------------------------------------------------------------------

has 'dbh' => (
    is  => 'ro',
    isa => InstanceOf ['DBI::db']
) ;

has 'prefix' => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'qsdb' ; },
) ;

has 'debug' => (
    is      => 'rw',
    default => sub { 0 ; },
    writer  => 'set_debug'
) ;

has 'skip_table_check' => (
    is      => 'ro',
    default => sub { 0 ; },
) ;

has 'subscriptions' => (
    is       => 'ro',
    init_arg => 0,
    default  => sub { {} },
) ;

# this is the number of events listened to
has 'ev_count' => (
    is       => 'ro',
    init_arg => 0,
    default  => sub { {} },
) ;

# when listening for chatter events we will wait for this many seconds
# before trying again
has 'listen_delay' => (
    is      => 'ro',
    default => sub {1},
) ;

has 'default_queue' => (
    is      => 'ro',
    isa     => Str,
    default => sub {""},
) ;

# -----------------------------------------------------------------------------
# once the class in instanciated then we need to ensure that we have the
# tables created

=head2 new

Create a new instance of a queue

B<Parameters>

Hash of

=over

=item dbh (required)

DBI database handle of database previously connected to

=item prefix

set a prefix name of the tables, allows you to have dev/test/live versions in the same database

=item debug  (optional)

set basic STDERR debugging on or off

=item skip_table_check

don't check to see if the tables need creating

=item default_queue

optionally provide a default queue to work with

=back

    my $queue = App::Basis::Queue->new( dbh => $dbh ) ;

=cut

sub BUILD
{
    my $self = shift ;

    $self->_set_db_type( $self->{dbh}->{Driver}->{Name} ) ;
    die("Valid Database connection required") if ( !$self->_db_type() ) ;

    # if we are using sqlite then we need to set a pragma to allow
    # cascading deletes on FOREIGN keys
    if ( $self->_db_type() eq 'SQLite' ) {
        $self->{dbh}->do("PRAGMA foreign_keys = ON") ;
    }

    # ensure we have the tables created (if wanted)
    $self->_create_tables() if ( !$self->skip_table_check ) ;

    # get the first list of queues we have
    $self->list_queues() ;
}

# -----------------------------------------------------------------------------
# TODO: add a DEMOLISH method to clean up unprocessed items when the object
# handle goes out of scope

# -----------------------------------------------------------------------------
## class private variables
# -----------------------------------------------------------------------------

has _queue_list => (
    is       => 'rwp',              # like ro, but creates _set_queue_list too
    lazy     => 1,
    default  => sub { {} },
    writer   => '_set_queue_list',
    init_arg => undef               # dont allow setting in constructor ;
) ;

has _db_type => (
    is       => 'rwp',              # like ro, but creates _set_queue_list too
    lazy     => 1,
    default  => sub {''},
    writer   => '_set_db_type',
    init_arg => undef               # dont allow setting in constructor ;
) ;

has _processor => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $hostname = `hostname` ;
        $hostname =~ s/\s//g ;
        $hostname . "::$ENV{USER}" . "::" . $$ ;
    },
    init_arg => undef               # dont allow setting in constructor ;
) ;

# -----------------------------------------------------------------------------
## class private methods
# -----------------------------------------------------------------------------

sub _debug
{
    my $self = shift ;

    return if ( !$self->{debug} ) ;

    my $msg = shift ;
    $msg =~ s/^/    /gsm ;

    say STDERR $msg ;
}

# -----------------------------------------------------------------------------
sub _build_sql_stmt
{
    my ( $query, $p ) = @_ ;
    our @params = $p ? @$p : () ;
    $query =~ s/\s+$// ;
    $query .= ' ;' if ( $query !~ /;$/ ) ;

# make sure we repesent NULL properly, do quoting - only basic its only for debug
    our $i = 0 ;
    {

        sub _repl
        {
            my $out = 'NULL' ;

            # quote strings, leave numbers untouched, not doing floats
            if ( defined $params[$i] ) {
                $out
                    = $params[$i] =~ /^\d+$/ ? $params[$i] : "'$params[$i]'" ;
            }
            $i++ ;

            return $out ;
        }
        $query =~ s/\?/_repl/gex if ( @params && scalar(@params) ) ;
    }

    return $query ;
}

# -----------------------------------------------------------------------------
sub _query_db
{
    state $sth_map = {} ;
    my $self = shift ;
    my ( $query, $p, $no_results ) = @_ ;
    my @params = $p ? @$p : () ;
    my %result ;

    $query =~ s/\s+$// ;
    $query .= ' ;' if ( $query !~ /;$/ ) ;

    if ( $self->{debug} ) {

        $self->_debug(
            "ACTUAL QUERY: $query\nQUERY PARAMS: " . to_json( \@params ) ) ;
        my $sql = _build_sql_stmt( $query, $p ) ;
        $self->_debug( 'BUILT QUERY : ' . $sql . "\n" ) ;
    }

    try {
        my $sth ;

        # key based on query and fields we are using
        my $key = "$query." . join( '.', @params ) ;
        if ( $sth_map->{$key} ) {
            $sth = $sth_map->{$key} ;
        } else {

            $sth = $self->{dbh}->prepare($query) ;

            # save the handle for next time
            $sth_map->{$key} = $sth ;

        }
        my $rv = $sth->execute(@params) ;
        if ( !$no_results ) {

            # so as to get an array of hashes
            $result{rows}      = $sth->fetchall_arrayref( {} ) ;
            $result{row_count} = scalar( @{ $result{rows} } ) ;
            $result{success}   = 1 ;

            $self->_debug(
                'QUERY RESPONSE: ' . to_json( $result{rows} ) . "\n" ) ;
        } else {
            if ($rv) {
                $result{row_count} = $sth->rows ;
                $result{success}   = 1 ;
            }
        }
    }
    catch {
        $result{error}
            = "Failed to prepare/execute query: $query\nparams: "
            . to_json($p)
            . "\nerror: $@\n" ;

        warn $result{error} ;
        # $self->_debug( $result{error} );
    } ;
    return \%result ;
}

# -----------------------------------------------------------------------------
sub _update_db
{
    my $self = shift ;
    my ( $table, $query, $params ) = @_ ;

    $query = "UPDATE $table $query" ;

    my $resp = $self->_query_db( $query, $params, 1 ) ;

    return $resp ;
}

# -----------------------------------------------------------------------------
# we will hold onto statement handles to speed up inserts

sub _insert_db
{
    state $sth_map = {} ;
    my $self = shift ;
    my ( $table, $f, $p ) = @_ ;
    my @params = $p ? @$p : () ;

    # key based on table and fields we are inserting
    my $key = "$table." . join( '.', @$f ) ;
    my ( $query, $sql, $sth ) ;

    if ( $sth_map->{$key} ) {
        $sth = $sth_map->{$key} ;
    } else {
        $query
            = "INSERT INTO $table ("
            . join( ',', @$f )
            . ") values ("
            . join( ',', map {'?'} @$f )
            . ") ;" ;

        $self->_debug($query) ;
        $sth = $self->{dbh}->prepare($query) ;

        # cache the handle for next time
        $sth_map->{$key} = $sth ;
    }
    my $rv = $sth->execute(@params) ;

    return { row_count => $rv, error => 0 } ;
}

# -----------------------------------------------------------------------------

sub _delete_db_record
{
    my $self = shift ;
    my ( $table, $q, $v ) = @_ ;
    my $query = "DELETE FROM $table $q ;" ;

    # run the delete and don't fetch results
    my $resp = $self->_query_db( $query, $v, 1 ) ;
    return $resp ;
}

# -----------------------------------------------------------------------------
# as all the indexes are constructued the same, lets have a helper
sub _create_index_str
{
    my ( $table, $field ) = @_ ;

    return sprintf( "CREATE INDEX %s_%s_idx on %s(%s) ;",
        $table, $field, $table, $field ) ;
}

# -----------------------------------------------------------------------------
sub _create_sqlite_table
{
    my $self = shift ;
    my ($table) = @_ ;
    $self->_debug("Creating SQLite tables") ;

    # set WAL mode rather than the default DELETE as its faster
    try { $self->{dbh}->do("PRAGMA journal mode = WAL;") ; } catch { } ;

    my $sql = "CREATE TABLE $table (
        counter         INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        id              VARCHAR(128) NOT NULL UNIQUE,
        queue_name      VARCHAR(128) NOT NULL,
        msg_type        VARCHAR(8),
        persist         BOOLEAN DEFAULT 0,
        added           TIMESTAMP DEFAULT current_timestamp,
        activates       TIMESTAMP DEFAULT current_timestamp,
        expires         TIMESTAMP,
        processed       BOOLEAN DEFAULT 0,
        processor       VARCHAR(128),
        process_start   TIMESTAMP,
        processing_time FLOAT,
        process_failure SMALLINT DEFAULT 0,
        data            TEXT   ) ;" ;

    $self->_debug($sql) ;
    try { $self->{dbh}->do($sql) ; } catch { } ;
}

# -----------------------------------------------------------------------------
sub _create_postgres_table
{
    my $self = shift ;
    my ($table) = @_ ;
    $self->_debug("Creating PostgreSQL tables") ;

    # big/serial creates an auto incrementing column in PostgreSQL
    my $sql = "CREATE TABLE $table (
        counter         BIGSERIAL PRIMARY KEY UNIQUE,
        id              VARCHAR(128) NOT NULL UNIQUE,
        queue_name      VARCHAR(128) NOT NULL,
        msg_type        VARCHAR(8),
        persist         BOOLEAN DEFAULT 0,
        added           TIMESTAMP WITH TIME ZONE DEFAULT now(),
        activates       TIMESTAMP WITH TIME ZONE DEFAULT now(),
        expires         TIMESTAMP,
        processed       SMALLINT DEFAULT 0,
        processor       VARCHAR(128),
        process_start   TIMESTAMP,
        processing_time FLOAT,
        process_failure SMALLINT DEFAULT 0,
        data            TEXT  ) ;" ;

    $self->_debug($sql) ;
    try { $self->{dbh}->do($sql) ; } catch { } ;
}

# -----------------------------------------------------------------------------
sub _create_mysql_table
{
    my $self = shift ;
    my ($table) = @_ ;
    $self->_debug("Creating MySQL tables") ;

    my $sql = "CREATE TABLE $table (
        counter         INT NOT NULL PRIMARY KEY AUTO_INCREMENT UNIQUE,
        id              VARCHAR(128) NOT NULL UNIQUE,
        queue_name      VARCHAR(128) NOT NULL,
        msg_type        VARCHAR(8),
        persist         BOOLEAN DEFAULT 0,
        added           TIMESTAMP DEFAULT current_timestamp,
        activates       TIMESTAMP DEFAULT current_timestamp,
        expires         TIMESTAMP,
        processed       SMALLINT DEFAULT 0,
        processor       VARCHAR(128),
        process_start   TIMESTAMP,
        processing_time FLOAT,
        process_failure SMALLINT DEFAULT 0,
        data            TEXT  ) ;" ;

    $self->_debug($sql) ;
    try { $self->{dbh}->do($sql) ; } catch { } ;
}

# -----------------------------------------------------------------------------
# create all the tables and indexes
sub _create_tables
{
    my $self = shift ;
    my $sql ;
    my $table = $self->{prefix} . '_queue' ;

    # as the checking for tables and indexes is fraught with issues
    # over multiple databases its easier to not print the errors and
    # catch the creation failures and ignore them!
    my $p = $self->{dbh}->{PrintError} ;
    $self->{dbh}->{PrintError} = 0 ;

    # I am assuming either table does not exist then nor does the
    # other and we should create both
    if ( $self->_db_type() eq 'SQLite' ) {
        $self->_create_sqlite_table($table) ;
    } elsif ( $self->_db_type() eq 'Pg' ) {
        $self->_create_postgres_table($table) ;
    } elsif ( $self->_db_type() eq 'mysql' ) {
        $self->_create_mysql_table($table) ;
    } else {
        die "Unhandled database type " . $self->_db_type() ;
    }

    foreach my $field (
        qw/counter id added activates queue_name msg_type persist expires processed process_failure/
        ) {
        my $sql = _create_index_str( $table, $field ) ;

        $self->_debug($sql) ;
        try { $self->{dbh}->do($sql) ; } catch { } ;
    }

    # create views

    # restore the PrintError setting
    $self->{dbh}->{PrintError} = $p ;
}

# -----------------------------------------------------------------------------
# always create the datetime strings the same way
sub _std_datetime
{
    my ($secs) = @_ ;
    $secs ||= time() ;
    return strftime( "%Y-%m-%d %H:%M:%S UTC", gmtime($secs) ) ;
}

# -----------------------------------------------------------------------------
# convert something like a datetime string or an epoch value into a standardised
# datetime string and epoch value

sub _parse_datetime
{
    my ($datetime) = @_ ;
    state $date = new Date::Manip::Date ;
    my @ret ;

    if ( !$datetime ) {
        return wantarray ? ( undef, undef ) : undef ;
    } elsif ( $datetime =~ /^\d+$/ ) {
        # assume anything less than five days is a time into the future
        $datetime += time() if ( $datetime <= FIVE_DAYS ) ;
        @ret = ( _std_datetime($datetime), $datetime ) ;
    } else {
        # so parse will parse in locale time not as UTC
        $date->parse($datetime) ;
        {
            # if we get a warning about converting the date to a day, there
            # must be a problem with parsing the input date string
            local $SIG{__WARN__} = sub {
                die "Invalid date, could not parse" ;
            } ;
            my $day = $date->printf("%a") ;
        }

        my $d2 = $date->printf("%O %Z") ;
        # reparse the date to get it into UTC, best way I could think of :(
        $date->parse($d2) ;

        # secs_since_1970_GMT is epoch
        @ret = (
            _std_datetime( $date->secs_since_1970_GMT() ),
            $date->secs_since_1970_GMT()
        ) ;
    }

    return wantarray ? @ret : $ret[0] ;
}

# -----------------------------------------------------------------------------
# _add
# Add some data into a named queue. Could be a task or a chatter mesg
# * This does not handle wildcard queues *

sub _add
{
    state $uuid = Data::UUID->new() ;
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "_add accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;

    # to keep what was here before the change to the parameters
    my $qname    = $params->{queue} ;
    my $msg_type = $params->{type} ;
    # only TASK events can activate in the future
    delete $params->{activates} if ( $msg_type ne MSG_TASK ) ;
    my $persist = $params->{persist} ;
    my ( $expires, $when ) = _parse_datetime( $params->{expires} ) ;
    my $activates = _parse_datetime( $params->{activates} ) ;
    $activates ||= _std_datetime() ;
    my $data = $params->{data} ;

    if ( ref($data) ne 'HASH' ) {
        warn "_add data parameter must be a hashref" ;
        return 0 ;
    }

    if ( $params->{expires} && $when && $when < time() ) {
        warn "_add not storing expired data" ;
        return 0 ;
    }

    my $status = 0 ;
    my $resp ;
    if ( !$qname || !$data ) {
        my $err = "Missing queue name or data" ;
        $self->_debug($err) ;
        warn $err ;
        return $status ;
    }
    if ( $qname =~ /\*/ ) {
        my $err = "Bad queue name, cannot contain '*'" ;
        $self->_debug($err) ;
        warn $err ;
        return $status ;
    }

    try {
        my $json_data = encode_json($data) ;

      # we manage the id's for the queue entries as we cannot depend
      # on a common SQL method of adding a record and getting its uniq ID back

        $expires ||= MAX_EXPIRY_DATETIME ;

        my $message_id = $uuid->create_b64() ;
        my $added      = _std_datetime() ;
        $resp = $self->_insert_db(
            $self->{prefix} . '_queue',
            [qw(id queue_name added data msg_type persist expires activates)],
            [   $message_id, $qname,   $added,   $json_data,
                $msg_type,   $persist, $expires, $activates
            ]
        ) ;

        $status = $message_id if ( !$resp->{error} ) ;
    }
    catch {
        my $e = $@ ;
        warn $e ;
    } ;

    return $status ;
}

# -----------------------------------------------------------------------------
# get size of a queue, add _qtype parameter as MSG_TASK or MSG_SIMPLE
sub _queue_size
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "queue_size accepts a hash or a hashref of parameters" ;
        return 0 ;
    }
    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # switch to SQL wildcard
    $qname =~ s/\*/%/g ;

    my $sql = sprintf(
        "SELECT count(*) as count FROM %s_queue
            WHERE queue_name LIKE ?
            AND msg_type = ?
            AND expires  > ?
            AND processed = 0
            AND process_failure = 0
; ", $self->{prefix}
    ) ;
            # AND process_failure = 0
    my $expires = _parse_datetime( time() ) ;
    my $resp
        = $self->_query_db( $sql, [ $qname, $params->{_qtype}, $expires ] ) ;

    return $resp->{row_count} ? $resp->{rows}->[0]->{count} : 0 ;
}

# -----------------------------------------------------------------------------

=head2 add

Add task data into a named queue. This creates a 'task' that needs to be processed.

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcard B<NOT allowed>

=item data

Data to store against the queue, can be a scalar, hashref or arrayref

=back

B<Example usage>

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

    # save some application audit data
    $queue->add(
        queue => 'app_start',
        data => {
            ip => 12.12.12.12, session_id => 12324324345, client_id => 248296432984,
            appid => 2, app_name => 'twitter'
        },
    ) ;

=cut

sub add
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "add accepts a hash or a hashref of parameters" ;
        return 0 ;
    }
    $params->{type}    = MSG_TASK ;
    $params->{persist} = 0 ;

    return $self->_add($params) ;
}

# -----------------------------------------------------------------------------

=head2 push

Push simple data onto the end of a named queue.

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcard B<NOT allowed>

=item data

Data to store against the queue, can be a scalar, hashref or arrayref

=back

B<Example usage>

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

    # save some application audit data
    $queue->push(
        queue => 'app_start',
        data => {
            ip => 12.12.12.12, session_id => 12324324345, client_id => 248296432984,
            appid => 2, app_name => 'twitter'
        },
    ) ;

=cut

sub push
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "add accepts a hash or a hashref of parameters" ;
        return 0 ;
    }
    $params->{type} = MSG_SIMPLE ;

    return $self->_add($params) ;
}


# -----------------------------------------------------------------------------

# pop could possibly be done in a transaction, find the item, mark it as processed

# -----------------------------------------------------------------------------

=head2 pop

Remove the top item from the named queue - the oldest item on the queue

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcards allowed

=back

B<Returns>

The message data only

B<Example usage>

    my $data = $queue->pop( queue => 'queue_name') ;

=cut

sub pop
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;
    my $popped ;

    if ( ref($params) ne 'HASH' ) {
        warn "process accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    my $processed_count = 0 ;
    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # if the queue does not exist
    return 0 if ( !$self->_valid_qname($qname) ) ;

    # switch to SQL wildcard
    $qname =~ s/\*/%/g ;

    # get list of IDs we can process, as SQLite has an issue
    # with ORDER BY and LIMIT in an UPDATE call so we have to do things
    # in 2 stages, which means it is not easy to mark lots of records
    # to be processed but that its possibly a good thing
    my $sql = sprintf(
        "SELECT * FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND msg_type = ?
            ORDER BY counter ASC
            LIMIT 1;", $self->{prefix}
    ) ;
    my $expires = _parse_datetime( time() ) ;
    my $info = $self->_query_db( $sql, [ $qname, MSG_SIMPLE ] ) ;

    # if there are no items to update, return
    # return if ( !scalar( $info->{rows} ) ) ;
    return if ( !$info->{row_count} ) ;

    my $row = $info->{rows}->[0] ;
    my $id  = $row->{id} ;

    # mark item that I have popped
    my $update
        = "SET processed=1, processor=?, process_start=?, processing_time=?, process_failure=0
        WHERE id = ? ;" ;
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $update, [ $self->_processor(), _std_datetime(), 0.0, $id ] ) ;
    if ( !$resp->{row_count} ) {
        return ;
    }
    # return unpacked data
    return decode_json( $row->{data} ) ;
}

# -----------------------------------------------------------------------------

=head2 size


Get size of a SIMPLE queue

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcards allowed

=back

B<Example usage>

    my $count = $queue->size( queue => 'queue_name') ;
    say "there are $count items in the queue" ;

    # size can manage wildcards
    $queue->size( queue => '/celestial/*') ;

=cut

sub size
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "size accepts a hash or a hashref of parameters" ;
        return 0 ;
    }
    $params->{_qtype} = MSG_SIMPLE ;
    return $self->_queue_size($params) ;
}


# -----------------------------------------------------------------------------
# try and find a match for the qname, replace SQL wildcard with perl ones

sub _valid_qname
{
    my $self = shift ;
    my ($qname) = @_ ;

    # update queue list
    $self->list_queues() ;

    $qname =~ s/%/*/g ;
    my $wild = ( $qname =~ /\*/ ) ? 1 : 0 ;

    my $match = 0 ;
    foreach my $q ( keys %{ $self->{_queue_list} } ) {
        if ( ( $wild && $q =~ $qname ) || $self->{_queue_list}->{$qname} ) {
            $match++ ;
            last ;
        }
    }

    return $match ;
}

# -----------------------------------------------------------------------------

=head2 process

Process up to 100 tasks from the named queue(s)

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcards allowed

=item count

Number of items to process from the queue

=item callback

coderef to be called to each queue item, expects queue (object), queue_name and the data of the queue item (record)

=back

A reference to the queue object is passed to the callback along with the name of
the queue and the record that is to be procssed.

If the callback returns a non-zero value then the record will be marked as processed.
If the callback returns a zero value, then the processing is assumed to have failed
and the failure count will be incremented by 1. If the failue count matches our
maximum allowed limit then the item will not be available for any further processing.

B<Example usage>

    sub processing_callback {
        my ( $queue, $qname, $record, $params ) = @_;
        # $params = { something => 'data'} ; from the process call

        return 1;
    }

    $queue->process(
        queue => 'queue_name',
        count => 5,
        callback => \&processing_callback
    ) ;

qname can contain wildcards and all matching queues will be scanned

    # add things to different queues, but with a common root
    $queue->add( queue => '/celestial/stars', data => { list: [ "sun", "alpha centuri"]}) ;
    $queue->add( queue => '/celestial/planets', data => { list: [ "earth", "pluto", "mars"]}) ;

    # process all the 'celestial' bodies queues
    $queue->process( queue => '/celestial/*', count => 5,
        callback => \&processing_callback,
        callback_params => { something => 'data'}
    ) ;

=cut

sub process
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "process accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    my $processed_count = 0 ;
    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # if the queue does not exist
    return 0 if ( !$self->_valid_qname($qname) ) ;

    # switch to SQL wildcard
    $qname =~ s/\*/%/g ;

    $params->{count} ||= 1 ;
    die __PACKAGE__ . " process requires a callback function"
        if ( !$params->{callback} || ref( $params->{callback} ) ne 'CODE' ) ;

    if ( $params->{count} > MAX_PROCESS_ITEMS ) {
        warn "Reducing process count from $params->{count} to "
            . MAX_PROCESS_ITEMS ;
        $params->{count} = MAX_PROCESS_ITEMS ;
    }

    my $now = _std_datetime() ;

    # get list of IDs we can process, as SQLite has an issue
    # with ORDER BY and LIMIT in an UPDATE call so we have to do things
    # in 2 stages, which means it is not easy to mark lots of records
    # to be processed but that its possibly a good thing
    my $sql = sprintf(
        "SELECT id FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND process_failure = 0
            AND msg_type = ?
            AND expires > ?
            AND activates <= ?
            ORDER BY added ASC
            LIMIT ?;", $self->{prefix}
    ) ;
    my $expires = _parse_datetime( time() ) ;
    my $ids     = $self->_query_db( $sql,
        [ $qname, MSG_TASK, $expires, $now, $params->{count} ] ) ;
    my @t ;
    foreach my $row ( @{ $ids->{rows} } ) {
        CORE::push @t, "'$row->{id}'" ;
    }

    # if there are no items to update, return
    return $processed_count if ( !scalar(@t) ) ;
    my $id_list = join( ',', @t ) ;

    # mark items that I am going to process
    my $update = "SET processor=?
            WHERE id IN ( $id_list) AND processed = 0 ;" ;
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $update, [ $self->_processor() ] ) ;
    return $processed_count if ( !$resp->{row_count} ) ;

    # refetch the list to find out which ones we are going to process,
    # in case another system was doing things at the same time
    $sql = sprintf(
        "SELECT * FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND processor = ?
            AND process_failure = 0
            AND msg_type = ?
            AND expires > ?
            AND activates <= ?
            ORDER BY added ASC
            LIMIT ?;", $self->{prefix}
    ) ;

    my $info = $self->_query_db(
        $sql,
        [   $qname, $self->_processor(), MSG_TASK, $expires,
            $now,   $params->{count}
        ]
    ) ;

    foreach my $row ( @{ $info->{rows} } ) {

        # unpack the data
        $row->{data} = decode_json( $row->{data} ) ;
        my $state   = 0 ;
        my $start   = _std_datetime() ;
        my $st      = [gettimeofday] ;
        my $invalid = 0 ;
        my $elapsed ;
        try {
            $state = $params->{callback}
                ->( $self, $qname, $row, $params->{callback_params} ) ;
        }
        catch {
            warn "process: error in callback $@" ;
            $invalid++ ;
        } ;
        $elapsed = tv_interval($st) ;

        if ($invalid) {

            # if the callback was invalid then we should not mark this
            # as a process failure just clear the processor
            $update = "SET processor=?, WHERE id = ? AND processed = 0 ;" ;
            $info   = $self->_update_db( $self->{prefix} . "_queue",
                $update, [ '', $row->{id} ] ) ;
        } elsif ($state) {

            # show we have processed it
            $update
                = "SET processed=1, process_start=?, processing_time=?  WHERE id = ? AND processed = 0 ;"
                ;
            $info = $self->_update_db( $self->{prefix} . "_queue",
                $update, [ $start, $elapsed, $row->{id} ] ) ;
            $processed_count++ ;
        } else {
            # mark the failure
            $update
                = "SET process_failure=1, processing_time=? WHERE id = ? AND processed = 0 ;"
                ;
            $info = $self->_update_db( $self->{prefix} . "_queue",
                $update, [ $elapsed, $row->{id} ] ) ;
        }
    }

    return $processed_count ;
}

# -----------------------------------------------------------------------------

=head2 process_failures, process_deadletters

Process up to 100 failed tasks from the queue

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcards allowed

=item count

Number of items to process from the queue

=item callback

Coderef to be called to each queue item, expects queue (object), queue_name and the data of the queue item (record)

=back

a refrence to the queue object is passed to the callback along with the name of the queue
and the record that is to be procssed. As these are failures we are not interested
in an value of the callback function.

B<Example usage>

    sub processing_failure_callback {
        my ( $queue, $qname, $record, $params ) = @_;
        # $params = { something => 'data'} ; from the process call

        # items before 2013 were completely wrong so we can delete
        if( $record->{added} < '2013-01-01') {
            $queue->delete_record( $record) ;
        } else {
            # failures in 2013 was down to a bad processing function
            $queue->reset_record( $record) ;
        }
    }

    $queue->process(
        queue => 'queue_name',
        count => 5,
        callback => \&processing_failure_callback,
        callback_params => { something => 'data'}
    ) ;

    # again we can use wildcards here for queue names

    # add things to different queues, but with a common root
    $queue->add( queue => '/celestial/stars', data => { list: [ "sun", "alpha centuri"]}) ;
    $queue->add( queue => '/celestial/planets', data => { list: [ "moon", "pluto", "mars"]}) ;
    # process, obviously 'moon' will fail our planet processing
    $queue->process(
        queue => 'queue_name',
        count => 5,
        callback => \&processing_callback,
        callback_params => { something => 'data'}

    ) ;

    # process all the 'celestial' bodies queues for failures - probably will just have the moon in it
    $queue->process_failures(
        queue => '/celestial/*',
        count => 5,
        callback => \&processing_failure_callback,
        callback_params => { something => 'data'}
    ) ;

=cut

sub process_failures
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "process_failures accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    my $processed_count = 0 ;

    # switch to SQL wildcard
    $qname =~ s/\*/%/g ;

    return 0 if ( !$self->_valid_qname($qname) ) ;

    $params->{count} ||= 1 ;
    die __PACKAGE__ . " process requires a callback function"
        if ( !$params->{callback} || ref( $params->{callback} ) ne 'CODE' ) ;

    if ( $params->{count} > MAX_PROCESS_ITEMS ) {
        warn "Reducing process_failures count from $params->{count} to"
            . MAX_PROCESS_ITEMS ;
        $params->{count} = MAX_PROCESS_ITEMS ;
    }

    my $now = _std_datetime() ;
    # get list of IDs we can process
    my $sql = sprintf(
        "SELECT id FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND process_failure = 1
            AND msg_type = ?
            AND expires > ?
            AND activates <= ?
            ORDER BY added ASC
            LIMIT ?;", $self->{prefix}
    ) ;
    my $expires = _parse_datetime( time() ) ;
    $expires |= "" ;

    my $ids = $self->_query_db( $sql,
        [ $qname, MSG_TASK, $expires, $now, $params->{count} ] ) ;
    my @t ;
    foreach my $row ( @{ $ids->{rows} } ) {
        CORE::push @t, "'$row->{id}'" ;
    }

    # if there are no items to update, return
    return $processed_count if ( !scalar(@t) ) ;
    my $id_list = join( ',', @t ) ;

    # mark items that I am going to process
    my $update = "SET processor=?
            WHERE id IN ( $id_list) AND processed = 0 ;" ;
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $update, [ $self->_processor() ] ) ;
    return $processed_count if ( !$resp->{row_count} ) ;

    # refetch the list to find out which ones we are going to process,
    # in case another system was doing things at the same time
    $sql = sprintf(
        "SELECT * FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND processor = ?
            AND process_failure = 1
            AND msg_type = ?
            AND expires > ?
            AND activates <= ?
            ORDER BY added ASC
            LIMIT ?;", $self->{prefix},
    ) ;
    my $info = $self->_query_db( $sql,
        [ $qname, $self->_processor(), MSG_TASK, $expires, $now, $params->{count} ] ) ;
    $self->{debug} = 0 ;

    foreach my $row ( @{ $info->{rows} } ) {

        # unpack the data
        $row->{data} = decode_json( $row->{data} ) ;

        my $state = 0 ;
        try {
            $state = $params->{callback}
                ->( $self, $qname, $row, $params->{callback_params} ) ;
        }
        catch {
            warn "process_failures: error in callback $@" ;
        } ;

      # we don't do anything else with the record, we assume that the callback
      # function will have done something like delete it or re-write it
    }

    return $processed_count ;
}

sub process_deadletters{
    my $self = shift ;
    return $self->process_failures( $self, @_) ;
}

# -----------------------------------------------------------------------------

=head2 queue_size

Get the count of unprocessed TASK items in the queue

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcards allowed

=back

B<Example usage>

    my $count = $queue->queue_size( queue => 'queue_name') ;
    say "there are $count unprocessed items in the queue" ;

    # queue size can manage wildcards
    $queue->queue_size( queue => '/celestial/*') ;

=cut

sub queue_size
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "queue_size accepts a hash or a hashref of parameters" ;
        return 0 ;
    }
    $params->{_qtype} = MSG_TASK ;
    return $self->_queue_size($params) ;
}

# -----------------------------------------------------------------------------

=head2 list_queues

Qbtains a list of all the queues used by this database

B<Example usage>

    my $qlist = $queue->list_queues() ;
    foreach my $q (@$qlist) {
        say $q ;
    }

=cut

sub list_queues
{
    my $self = shift ;
    my %ques ;

    my $result = $self->_query_db(
        sprintf( 'SELECT DISTINCT queue_name FROM %s_queue;',
            $self->{prefix} )
    ) ;

    if ( !$result->{error} ) {
        %ques = map { $_->{queue_name} => 1 } @{ $result->{rows} } ;
    }

    $self->_set_queue_list( \%ques ) ;

    return [ keys %ques ] ;
}

# -----------------------------------------------------------------------------

=head2 peek

Have a look at an unprocessed item in a TASK queue

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcards allowed

=item position

position in the queue you want to peek at (head/start) or (tail/end) - defaults to head

=item count

number of items to peek, defaults to 1, max is 100 (PEEK_MAX)

=back

B<Returns>

Hashref with the following fields queue_name added activates expires data

B<Example usage>

    my $data = $queue->peek( queue => 'queue_name', position => 'head') ;

=cut

sub peek
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;
    my $popped ;

    if ( ref($params) ne 'HASH' ) {
        warn "process accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # if the queue does not exist
    return 0 if ( !$self->_valid_qname($qname) ) ;

    # switch to SQL wildcard
    $qname =~ s/\*/%/g ;

    my $direction = 'ASC' ;
    $params->{position} ||= 'head' ;
    $params->{count}    ||= 1 ;
    $params->{count} = PEEK_MAX if( $params->{count} > PEEK_MAX) ;

    if ( $params->{position} =~ /(end|tail|last)/i ) {
        $direction = 'DESC' ;
    } elsif ( $params->{position} !~ /(start|head|first)/i ) {
        warn(
            "peek position '$params->{position}' is not valid, defaulting to head"
        ) ;
    }

    # find some unprocessed items
    my $sql = sprintf(
        "SELECT * FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND process_failure = 0
            AND msg_type = ?
            AND expires > ?
            ORDER BY counter $direction
            LIMIT ?;", $self->{prefix}
    ) ;
    my $expires = _parse_datetime( time() ) ;
    my $info
        = $self->_query_db( $sql, [ $qname, MSG_TASK, $expires, $params->{count} ] ) ;

    # if there are no items found return
    # if ( !scalar( $info->{rows} ) ) {
    if ( !$info->{row_count} ) {
        return wantarray ? () : undef ;
    }

    my @data ;
    foreach my $row ( @{ $info->{rows} } ) {
        $row->{data} = decode_json( $row->{data} ) ;
        # remove things we do not want to share
        foreach my $f (
            qw(counter id msg_type persist processed processor process_start processing_time process_failure)
            ) {
            delete $row->{$f} ;
        }
        CORE::push @data, $row ;
    }

    return wantarray ? @data : $data[0] ;
}

# -----------------------------------------------------------------------------

=head2 stats

Obtains stats about the task data in the queue, this may be time/processor intensive
so use with care!

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcards allowed

=back

provides counts of unprocessed, processed, failures
max process_failure, avg process_failure, earliest_added, latest_added,
min_data_size, max_data_size, avg_data_size, total_records
avg_elapsed, max_elapsed, min_elapsed

B<Example usage>

    my $stats = $queue->stats( queue => 'queue_name') ;
    say "processed $stats->{processed}, failures $stats->{failure}, unprocessed $stats->{unprocessed}" ;

    # for all matching wildcard queues
    my $all_stats = $queue->stats( queue => '/celestial/*') ;

=cut

sub stats
{
    my $self    = shift ;
    my $params  = @_ % 2 ? shift : {@_} ;
    my $expires = _parse_datetime( time() ) ;

    if ( ref($params) ne 'HASH' ) {
        warn "stats accepts a hash or a hashref of parameters" ;
        return {} ;
    }
    $params->{queue} ||= $self->{default_queue} ;
    my $qname     = $params->{queue} ;
    my %all_stats = () ;

    # update queue list
    $self->list_queues() ;

    # switch to SQL wildcard
    $qname =~ s/%/*/g ;

    # work through all the queues and only count that match our qname
    foreach my $q ( keys %{ $self->{_queue_list} } ) {
        next if ( !$self->_valid_qname($q) ) ;
        next if ( ( $qname =~ /\*/ && $qname !~ $q ) || $qname ne $q ) ;

        # queue_size also calls list_queues, so we don't need to do it!
        $all_stats{unprocessed} += $self->queue_size( queue => $q ) ;

        my $sql = sprintf(
            "SELECT count(*) as count
            FROM %s_queue
            WHERE queue_name = ?
            AND msg_type = ?
            AND expires > ?
            AND processed = 1 ;", $self->{prefix}
        ) ;
        my $resp = $self->_query_db( $sql, [ $q, MSG_TASK, $expires ] ) ;
        $all_stats{processed} += $resp->{rows}->[0]->{count} || 0 ;

        $sql = sprintf(
            "SELECT count(*) as count FROM %s_queue
            WHERE queue_name = ?
            AND processed = 0
            AND msg_type = ?
            AND expires > ?
            AND process_failure = 1 ;", $self->{prefix}
        ) ;
        $resp = $self->_query_db( $sql, [ $q, MSG_TASK, $expires ] ) ;
        $all_stats{failures} += $resp->{rows}->[0]->{count} || 0 ;
    }

    # get all the stats for all matching queues
    my $sql = sprintf(
        "SELECT
                min(process_failure) as min_process_failure,
                max(process_failure) as max_process_failure,
                avg(process_failure) as avg_process_failure,
                min(added) as earliest_added,
                max(added) as latest_added,
                min( length(data)) as min_data_size,
                max( length(data)) as max_data_size,
                avg( length(data)) as avg_data_size,
                min( processing_time) as min_elapsed,
                max( processing_time) as max_elapsed,
                avg( processing_time) as avg_elapsed
            FROM %s_queue
            WHERE queue_name LIKE ?
            AND msg_type = ?
            AND expires > ?
            ;", $self->{prefix}
    ) ;
    my $resp = $self->_query_db( $sql, [ $qname, MSG_TASK, $expires ] ) ;

    foreach my $k ( keys %{ $resp->{rows}->[0] } ) {
        if ( $k =~ /_added/ ) {

        } else {
            $all_stats{$k} += $resp->{rows}->[0]->{$k} || "0" ;
        }
    }

    # number of records in the table
    $all_stats{total_records}
        = ( $all_stats{processed}   // 0 )
        + ( $all_stats{unprocessed} // 0 )
        + ( $all_stats{failures}    // 0 ) ;
    $all_stats{total_records} ||= '0' ;

    # make sure these things have a zero value so calculations don't fail
    foreach my $f (
        qw( unprocessed  processed  failures
        max process_failure avg earliest_added latest_added
        min_data_size  max_data_size avg_data_size total_records
        total_records min_proc max_proc avg_proc)
        ) {
        $all_stats{$f} ||= '0' ;
    }
    # $all_stats{dead_letters} = $all_stats{process_failure} ;

    return \%all_stats ;
}

# -----------------------------------------------------------------------------

=head2 delete_record

Delete a single task record from the queue

B<Parameters>

=over

=item record

Hashref to a record fetched with process or process_failures/deadletters

=back

Requires a data record which contains infomation we will use to determine the record

May be used in processing callback functions

B<Example usage>

    sub processing_callback {
        my ( $queue, $qname, $record, $params ) = @_;

        # lets remove records before 2013
        if( $record->{added) < '2013-01-01') {
            $queue->delete_record( $record) ;
        }
        return 1 ;
    }

=cut

sub delete_record
{
    my $self = shift ;
    my ($data) = @_ ;

    my $sql = "WHERE id = ?
        AND queue_name = ?
        AND msg_type = ?" ;
    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        $sql, [ $data->{id}, $data->{queue_name}, MSG_TASK ] ) ;

    return $resp->{row_count} ;
}

# -----------------------------------------------------------------------------

=head2 reset_record

Clear the failure flag from a failed task record

B<Parameters>

=over

=item record

Hashref of data fetched with process or process_failure/deadletters

=back

Requires a data record which contains infomation we will use to determine the record

may be used in processing callback functions

B<Example usage>

    sub processing_callback {
        my ( $queue, $qname, $record, $params ) = @_;

        # allow partially failed (and failed) records to be processed
        if( $record->{process_failure) {
            $queue->reset_record( $record) ;
        }
        return 1 ;
    }

=cut

sub reset_record
{
    my $self = shift ;
    my ($data) = @_ ;

    my $sql = "SET process_failure=0
        WHERE id = ?
        AND queue_name = ?
        AND processed=0
        AND process_failure > 0
        AND msg_type = ?" ;
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $sql, [ $data->{id}, $data->{queue_name}, MSG_TASK ] ) ;

    return $resp->{row_count} ;
}

# -----------------------------------------------------------------------------

=head2 publish

Publish some chatter data into a named queue.

B<Parameters>

Hash of

=over

=item queue

Name of the queue to publish to, wildcards B<NOT allowed>

=item data

Hashref of the data to be published

=item persist (optional)

Flag to show that this data data should be persisited (0 or 1).
This will become the only persistent record available until either it is replaced or expires.

=item expires (optional)

Time after which this data should be ignored. Accepts unix epoch time or parsable datetime string

=back

B<Example usage>

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

    # keep track of a bit of info
    $queue->publish( queue => 'app_log',
        data => {
            ip => 12.12.12.12, session_id => 12324324345, client_id => 248296432984,
            appid => 2, app_name => 'twitter'
        }
    ) ;

=cut

sub publish
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "publish accepts a hash or a hashref of parameters" ;
        return 0 ;
    }
    $params->{type} = MSG_CHATTER ;

    # make sure this is a zero or one value
    $params->{persist} = defined $params->{persist} ;

    return $self->_add($params) ;
}

# -----------------------------------------------------------------------------
# find the most recent persistent item
# queue is the only parameter, returns arrayref of items

sub _recent_persist
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "_recent_persist accepts a hash or a hashref of parameters" ;
        return [] ;
    }
    my $qname = $params->{queue} ;
    my @data ;

    # if the queue does not exist
    return [] if ( !$self->_valid_qname($qname) ) ;

    # switch to SQL wildcard
    $qname =~ s/\*/%/g ;

    # find the most recent persistent items for each matching queue
    my $sql = sprintf(
        "SELECT * FROM %s_queue a
            WHERE a.queue_name LIKE ?
            AND a.msg_type = ?
            AND a.persist = ?
            AND a.counter NOT IN ( SELECT counter from %s_queue b
            WHERE b.queue_name = a.queue_name
                AND b.msg_type = a.msg_type
                AND b.persist = a.persist
                AND b.added > a.added
            )
            AND a.expires > ?
            GROUP BY queue_name
            ORDER BY queue_name;", $self->{prefix}, $self->{prefix}
    ) ;

    # there should only be one persist item
    my $expires = _parse_datetime( time() ) ;

    my $result
        = $self->_query_db( $sql, [ $qname, MSG_CHATTER, 1, $expires ] ) ;

    foreach my $row ( @{ $result->{rows} } ) {
        $row->{data} = decode_json( $row->{data} ) ;    # unpack the data
        CORE::push @data, $row ;
    }

    return \@data ;
}

# -----------------------------------------------------------------------------
# get chatter data (ordered by datetime added) after a unix time
# queue is the only parameter,
# returns arrayref of items

sub _recent_chatter
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "_recent_chatter accepts a hash or a hashref of parameters" ;
        return [] ;
    }

    my $qname = $params->{queue} ;
    my @data ;

    # if the queue does not exist
    return [] if ( !$self->_valid_qname($qname) ) ;

    # switch to SQL wildcard
    $qname =~ s/\*/%/g ;

    my $result ;
    my $sql ;

    if ( $params->{counter} ) {
        $sql = sprintf(
            "SELECT * FROM %s_queue
                    WHERE queue_name LIKE ?
                    AND msg_type = ?
                    AND counter > ?
                    AND expires > ?
                    GROUP BY queue_name
                    ORDER BY counter;", $self->{prefix}
        ) ;

        my $expires = _parse_datetime( time() ) ;
        $expires |= "" ;

        $result = $self->_query_db( $sql,
            [ $qname, MSG_CHATTER, $params->{counter}, $expires ] ) ;

    } else {
        # check by date
        $sql = sprintf(
            "SELECT * FROM %s_queue
                    WHERE queue_name LIKE ?
                    AND msg_type = ?
                    AND added >= ?
                    AND expires > ?
                    ORDER BY counter;", $self->{prefix}
        ) ;

        my $expires = _parse_datetime( time() ) ;
        $result = $self->_query_db( $sql,
            [ $qname, MSG_CHATTER, $params->{after} // 0, $expires ] ) ;
    }

    foreach my $row ( @{ $result->{rows} } ) {
        $row->{data} = decode_json( $row->{data} ) ;    # unpack the data
        CORE::push @data, $row ;
    }

    return \@data ;
}

# -----------------------------------------------------------------------------

=head2 subscribe

Subscribe to a named queue with a callback.

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcard allowed

=item callback

Coderef to handle any matched events

=item after (optional)

Unix time after which to listen for events, defaults to now,  if set will skip persistent item checks

=item persist (optional)

Include the most recent persistent item, if using a wild card, this will match all the queues and could find multiple persistent items

=back

B<Example usage>

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

    # keep track of a bit of info
    $queue->subscribe( queue => 'app_logs/*', callback => \&handler) ;
    $queue->listen() ;

=cut

sub subscribe
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "subscribe accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    if ( !$params->{queue} ) {
        warn "subscribe needs a queue name to listen to" ;
        return 0 ;
    }

    if ( ref( $params->{callback} ) ne 'CODE' ) {
        warn "subscribe needs a callback handler to send events to" ;
        return 0 ;
    }

    # add to our current subscriptions

    if ( $params->{after} ) {

        # we cannot get recent persist item if they want to check after a date
        $params->{persist} = 0 ;
    }

    if ( !defined $params->{after} ) {
        $params->{after} = _std_datetime() ;
    } elsif ( $params->{after} =~ /^\d+$/ ) {
        $params->{after} = _std_datetime( gmtime( $params->{after} ) ) ;
    } elsif ( $params->{after} !~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ ) {
        warn(
            "this does not look like a datetime value I can use: '$params->{after}'"
        ) ;
        $params->{after} = _std_datetime() ;
    }

    $self->{subscriptions}->{ $params->{queue} } = {
        callback => $params->{callback},

        # when do we want events from
        after    => $params->{after},
        persist  => $params->{persist},
        ev_count => 0,
        counter  => 0
    } ;
}

# -----------------------------------------------------------------------------

=head2 listen

Listen to all subcribed channels. Loops forever unless told to stop.
If there is a persistent message in a queue, this will be passed to the callback before the other records.

B<Parameters>

Hash of

=over

=item events (optional)

Minimum number of events to listen for, stop after this many,  may stop after more - this is across ALL the subscriptions

=item datetime (optional)

Unix epoch time or parsable datetime when to stop listening

=item persist (optional)

Include the most recent persistent item, if subscribed using using a wild card,
this will match all the queues and could find multiple persistent items

=item listen_delay (optional)

Override the class delay, obtain events at this rate

=back

B<returns>

Number of chatter events actually passed to ALL the handlers

B<Example usage>

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;
    $queue->subscribe( '/logs/*', \&handler) ;
    $queue->listen() ;    # listening forever

    # or listen until christmas, checking every 30s
    $queue->subscribe( '/presents/*', \&handler) ;
    $queue->listen( datetime => '2015-12-25', listen_delay => 30) ;

=cut

sub listen
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;
    # decide where the delay comes from
    my $delay = $params->{listen_delay} || $self->{listen_delay} ;

    if ( ref($params) ne 'HASH' ) {
        warn "listen accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    if ( $params->{datetime} ) {
        my (@dt) = _parse_datetime( $params->{datetime} ) ;
        if ( $dt[1] ) {
            # used to check against time() later
            $params->{datetime} = $dt[1] ;
        }
    }

    if ( !keys %{ $self->{subscriptions} } ) {
        warn "you have not subscribed to any queues" ;
        return 0 ;
    }

    $self->{ev_count} = 0 ;

    # clean things up before we listen
    foreach my $qmatch ( sort keys %{ $self->{subscriptions} } ) {
        my $subs = $self->{subscriptions}->{$qmatch} ;
        $subs->{counter}  = 0 ;
        $subs->{ev_count} = 0 ;
    }

    # loop forever unless there is a reason to stop
    my $started = 0 ;
    while (1) {

        foreach my $qmatch ( sort keys %{ $self->{subscriptions} } ) {
            my $subs = $self->{subscriptions}->{$qmatch} ;

            # we may not want the most recent persistent record
            next if ( !$started && !$subs->{persist} ) ;

            my $items ;
            if ( !$started ) {
                $items = $self->_recent_persist( queue => $qmatch ) ;
            } else {
                $items = $self->_recent_chatter(
                    queue   => $qmatch,
                    after   => $subs->{after},
                    counter => $subs->{counter},
                ) ;
            }

            my $state ;
            foreach my $row ( @{$items} ) {

                $subs->{ev_count}++ ;    # count matches for this queue
                $self->{ev_count}++ ;    # and overall
                try {
                    # qmatch is the name of the queue matcher
                    $state = $subs->{callback}
                        ->( $self, $row->{queue_name}, $row ) ;
                    if ( $row->{added} gt $subs->{after} ) {
                        $subs->{after} = $row->{added} ;
                    }
                    if ( $row->{counter} > $subs->{counter} ) {
                        $subs->{counter} = $row->{counter} ;
                    }
                }
                catch {
                    warn "listen: error in callback $@" ;
                } ;
            }
        }
        $started = 1 ;
        last
            if ( $params->{events}
            && $self->{ev_count} > $params->{events} ) ;
        last
            if ( $params->{datetime}
            && time() > $params->{datetime} ) ;

        # wait a bit to allow the queues to fillup
        sleep($delay) ;
    }

    return $self->{ev_count} ;
}

# -----------------------------------------------------------------------------

=head2 unsubscribe

Unsubscribe from a named queue.

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcard allowed

=back

B<Example usage>

    sub handler {
        state $counter = 0 ;
        my $q = shift ;             # we get the queue object
        # the queue trigger that matched, the actual queue name and the data
        my ($qmatch, $queue, $data) = @_ ;

        # we are only interested in 10 messages
        if( ++$counter > 10) {
            $q->unsubscribe( queue => $queue) ;
        } else {
            say Data::Dumper( $data) ;
        }
    }

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;
    $queue->subscribe( queue => '/logs/*', callback => \&handler) ;
    $queue->listen() ;

=cut

sub unsubscribe
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "unsubscribe accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    if ( $params->{queue} ) {

        # does not matter if the queue name does not exist!
        delete $self->{subscriptions}->{ $params->{queue} } ;
    }
}

# -----------------------------------------------------------------------------

=head2 purge_tasks

Purge will remove all processed task items and failures/deadletters (process_failure >= 5).
These are completely removed from the database

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcard allowed

=item before (optional)

Unix epoch or parsable datetime before which items should be purged

defaults to 'now'

=back

B<Example usage>

    my $before = $queue->stats( queue => 'queue_name', before => '2015-11-24') ;
    $queue->purge_tasks( queue => 'queue_name') ;
    my $after = $queue->stats( queue  => 'queue_name') ;

    say "removed " .( $before->{total_records} - $after->{total_records}) ;

=cut

sub purge_tasks
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "purge_tasks accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # SQL wildcard replace
    $qname =~ s/\*/%/g ;

    try {
        if ( !defined $params->{before} ) {
            $params->{before} = _parse_datetime( time() ) ;
        } else {
            $params->{before} = _parse_datetime( $params->{before} ) ;
        }
    }
    catch {
        warn(
            "this does not look like a datetime value I can use: '$params->{before}'"
        ) ;
        $params->{before} = _parse_datetime( time() ) ;
    } ;

# TODO: add in expired items too, plus the and processed=1 or process_failure =1 looks a bit wrong
    my $sql = "WHERE queue_name LIKE ?
        AND processed = 1
        OR process_failure = 1
        AND msg_type = ?
        AND added <= ?" ;

    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        $sql, [ $qname, MSG_TASK, $params->{before} ] ) ;

    # return the number of items deleted
    return $resp->{row_count} ;
}

# -----------------------------------------------------------------------------

=head2 purge_chatter

purge will remove all chatter messages.
These are completely removed from the database

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcard allowed

=item before (optional)

Unix epoch or parsable datetime before which items should be purged

defaults to 'now'

=back

B<Example usage>

    my $del = $queue->purge_chatter( queue => 'queue_name', before => '2015-11-24') ;

    say "removed $del messages" ;

=cut

sub purge_chatter
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "purge_chatter accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # SQL wildcard replace
    $qname =~ s/\*/%/g ;

    my $sql = "WHERE queue_name LIKE ?
        AND processed = 1
        OR process_failure = 1
        AND msg_type = ?
        AND added <= ?" ;
    my $sql_args = [ $qname, MSG_CHATTER, $params->{before} ] ;

    if ( defined $params->{counter} ) {
        my $sql = "WHERE queue_name LIKE ?
        AND processed = 1
        OR process_failure = 1
        AND msg_type = ?
        AND counter <= ?" ;
        my $sql_args = [ $qname, MSG_CHATTER, $params->{counter} ] ;

    } else {
        try {
            if ( !defined $params->{before} ) {
                $params->{before} = _parse_datetime( time() ) ;
            } else {
                $params->{before} = _parse_datetime( $params->{before} ) ;
            }
        }
        catch {
            warn(
                "this does not look like a datetime value I can use: '$params->{before}'"
            ) ;
            $params->{before} = _parse_datetime( time() ) ;
        } ;
    }

    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        $sql, $sql_args ) ;

    # return the number of items deleted
    return $resp->{row_count} ;
}

# -----------------------------------------------------------------------------

=head2 remove_queue

Remove a queue and all of its records (task and chatter)

B<Parameters>

Takes a hash of

=over

=item queue

Name of the queue, wildcards allowed

=back

B<Example usage>

    $queue->remove_queue( queue => 'queue_name') ;
    my $after = $queue->list_queues() ;
    # convert list into a hash for easier checking
    my %a = map { $_ => 1} @after ;
    say "queue removed" if( !$q->{queue_name}) ;

=cut

sub remove_queue
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "remove_queue accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # SQL wildcard replace
    $qname =~ s/\*/%/g ;

    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        "WHERE queue_name LIKE ?", [$qname] ) ;
    return $resp->{success} ;
}

# -----------------------------------------------------------------------------

=head2 reset_failures, reset_deadletters

Clear any process_failure values from all unprocessed task items

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcard allowed

=back

B<Example usage>

    my $before = $queue->stats( queue => 'queue_name') ;
    $queue->reset_failures( queue => 'queue_name') ;
    my $after = $queue->stats( queue => 'queue_name') ;

    say "reset " .( $after->{unprocessed} - $before->{unprocessed}) ;

=cut

sub reset_failures
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "reset_failures accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # SQL wildcard replace
    $qname =~ s/\*/%/g ;

    my $sql = "SET process_failure=0" ;
    $sql .= " WHERE queue_name LIKE ?
        AND process_failure = 1
        AND msg_type = ?" ;
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $sql, [ $qname, MSG_TASK ] ) ;

    return $resp->{row_count} ? $resp->{row_count} : 0 ;
}

sub reset_deadletters {
    my $self = shift ;
    return $self->reset_failures( $self, @_) ;
}

# -----------------------------------------------------------------------------

=head2 remove_failures, remove_deadletters

Permanently delete task failures from the database

B<Parameters>

Hash of

=over

=item queue

Name of the queue, wildcard allowed

=back

B<Example usage>

    $queue->remove_failues( queue => 'queue_name') ;
    my $stats = $queue->stats( queue => 'queue_name') ;
    say "failues left " .( $stats->{failures}) ;

=cut

sub remove_failures
{
    my $self = shift ;
    my $params = @_ % 2 ? shift : {@_} ;

    if ( ref($params) ne 'HASH' ) {
        warn "remove_failures accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    $params->{queue} ||= $self->{default_queue} ;
    my $qname = $params->{queue} ;

    # SQL wildcard replace
    $qname =~ s/\*/%/g ;

    my $sql  = "WHERE process_failure = 1 AND msg_type = ?" ;
    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        $sql, [MSG_TASK] ) ;

    return $resp->{row_count} ;
}

sub remove_deadletters {
    my $self = shift ;
    return $self->reset_failures( $self, @_) ;
}

# -----------------------------------------------------------------------------

=head2 remove_tables

If you never need to use the database again, it can be completely removed

B<Example usage>

    $queue_>remove_tables() ;

=cut

sub remove_tables
{
    my $self = shift ;

    my $sql = sprintf( 'DROP TABLE %s_queue;', $self->{prefix} ) ;
    $self->_debug($sql) ;
    $self->{dbh}->do($sql) ;
}

# -----------------------------------------------------------------------------

1 ;
