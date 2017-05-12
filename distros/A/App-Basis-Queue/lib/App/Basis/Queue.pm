# ABSTRACT: Simple database backed FIFO queues

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
        my ( $queue, $qname, $record ) = @_;

        # call the payment system
        # pay_money( $record->{client_id}, $record->{amount}) ;

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
         callback => \&processing_callback
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

=head1 NOTES

I would use msgpack instead of JSON to store the data, but processing BLOBS in PostgreSQL is tricky.

To make the various inserts/queries work faster I cache the prepared statement handles against
a key and the fields that are being inserted, this speeds up the inserts roughly by 3x

=head1 AUTHOR

kmulholland, moodfarm@cpan.org

=head1 VERSIONS

v0.1  2013-08-02, initial work

=head1 TODO

Currently the processing functions only process the earliest MAX_PROCESS_ITEMS but
by making use of the counter in the info table, then we could procss the entire table
or at least a much bigger number and do it in chunks of MAX_PROCESS_ITEMS

Processing could be by date

Add a method to move processed items to queue_name/processed and failures to queue_name/failures or
add them to these queues when marking them as processed or failed, will need a number of other methods to
be updated but keeps less items in the unprocessed queue

=head1 See Also

L<Queue::DBI>, L<AnyMQ::Queue>, L<Minion>

=head1 API

=cut

package App::Basis::Queue;
$App::Basis::Queue::VERSION = '000.400.000';
use 5.10.0;
use feature 'state';
use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base qw/InstanceOf HashRef Str/;
use JSON;
use Data::UUID;
use Try::Tiny;
use POSIX qw( strftime);
use Time::HiRes qw(gettimeofday tv_interval );

# use Data::Printer ;

# -----------------------------------------------------------------------------

use constant MSG_TASK          => 'task';
use constant MSG_CHATTER       => 'chatter';
use constant MAX_PROCESS_ITEMS => 100;

# -----------------------------------------------------------------------------
## class initialisation
## instancation variables
# -----------------------------------------------------------------------------

has 'dbh' => (
    is  => 'ro',
    isa => InstanceOf ['DBI::db']
);

has 'prefix' => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'qsdb'; },
);

has 'debug' => (
    is      => 'rw',
    default => sub { 0; },
    writer  => 'set_debug'
);

has 'skip_table_check' => (
    is      => 'ro',
    default => sub { 0; },
);

has 'subscriptions' => (
    is       => 'ro',
    init_arg => 0,
    default  => sub { {} },
);

# this is the number of events listened to
has 'ev_count' => (
    is       => 'ro',
    init_arg => 0,
    default  => sub { {} },
);

# when listening for chatter events we will wait for this many seconds
# before trying again
has 'listen_delay' => (
    is      => 'ro',
    default => sub {1},
);

# -----------------------------------------------------------------------------
# once the class in instanciated then we need to ensure that we have the
# tables created

=head2 B<new>

Create a new instance of a queue

prefix - set a prefix name of the tables, allows you to have dev/test/live versions in the same database
debug - set basic STDERR debugging on or off
skip_table_check - don't check to see if the tables need creating

    my $queue = App::Basis::Queue->new( dbh => $dbh ) ;

=cut

sub BUILD {
    my $self = shift;

    $self->_set_db_type( $self->{dbh}->{Driver}->{Name} );
    die("Valid Database connection required") if ( !$self->_db_type() );

    # if we are using sqlite then we need to set a pragma to allow
    # cascading deletes on FOREIGN keys
    if ( $self->_db_type() eq 'SQLite' ) {
        $self->{dbh}->do("PRAGMA foreign_keys = ON");
    }

    # ensue we have the tables created (if wanted)
    $self->_create_tables() if ( !$self->skip_table_check );

    # get the first list of queues we have
    $self->list_queues();
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
);

has _db_type => (
    is       => 'rwp',              # like ro, but creates _set_queue_list too
    lazy     => 1,
    default  => sub {''},
    writer   => '_set_db_type',
    init_arg => undef               # dont allow setting in constructor ;
);

has _processor => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $hostname = `hostname`;
        $hostname =~ s/\s//g;
        $hostname . "::$ENV{USER}" . "::" . $$;
    },
    init_arg => undef               # dont allow setting in constructor ;
);

# -----------------------------------------------------------------------------
## class private methods
# -----------------------------------------------------------------------------

sub _debug {
    my $self = shift;

    return if ( !$self->{debug} );

    my $msg = shift;
    $msg =~ s/^/    /gsm;

    say STDERR $msg;
}

# -----------------------------------------------------------------------------
sub _build_sql_stmt {
    my ( $query, $p ) = @_;
    our @params = $p ? @$p : ();
    $query =~ s/\s+$//;
    $query .= ' ;' if ( $query !~ /;$/ );

# make sure we repesent NULL properly, do quoting - only basic its only for debug
    our $i = 0;
    {

        sub _repl {
            my $out = 'NULL';

            # quote strings, leave numbers untouched, not doing floats
            if ( defined $params[$i] ) {
                $out = $params[$i] =~ /^\d+$/ ? $params[$i] : "'$params[$i]'";
            }
            $i++;

            return $out;
        }
        $query =~ s/\?/_repl/gex if ( @params && scalar(@params) );
    }

    return $query;
}

# -----------------------------------------------------------------------------
sub _query_db {
    state $sth_map = {};
    my $self = shift;
    my ( $query, $p, $no_results ) = @_;
    my @params = $p ? @$p : ();
    my %result;

    $query =~ s/\s+$//;
    $query .= ' ;' if ( $query !~ /;$/ );

    if ( $self->{debug} ) {

        $self->_debug(
            "ACTUAL QUERY: $query\nQUERY PARAMS: " . to_json( \@params ) );
        my $sql = _build_sql_stmt( $query, $p );
        $self->_debug( 'BUILT QUERY : ' . $sql . "\n" );
    }

    try {
        my $sth;

        # key based on query and fields we are using
        my $key = "$query." . join( '.', @params );
        if ( $sth_map->{$key} ) {
            $sth = $sth_map->{$key};
        }
        else {

            $sth = $self->{dbh}->prepare($query);

            # save the handle for next time
            $sth_map->{$key} = $sth;

        }
        my $rv = $sth->execute(@params);
        if ( !$no_results ) {

            # so as to get an array of hashes
            $result{rows}      = $sth->fetchall_arrayref( {} );
            $result{row_count} = scalar( @{ $result{rows} } );
            $result{success}   = 1;

            $self->_debug(
                'QUERY RESPONSE: ' . to_json( $result{rows} ) . "\n" );
        }
        else {
            if ($rv) {
                $result{row_count} = $sth->rows;
                $result{success}   = 1;
            }
        }

    }
    catch {
        $result{error}
            = "Failed to prepare/execute query: $query\nparams: "
            . to_json($p)
            . "\nerror: $@\n";

        # $self->_debug( $result{error} );
    };
    return \%result;
}

# -----------------------------------------------------------------------------
sub _update_db {
    my $self = shift;
    my ( $table, $query, $params ) = @_;

    $query = "UPDATE $table $query";

    my $resp = $self->_query_db( $query, $params, 1 );

    return $resp;
}

# -----------------------------------------------------------------------------
# we will hold onto statement handles to speed up inserts

sub _insert_db {
    state $sth_map = {};
    my $self = shift;
    my ( $table, $f, $p ) = @_;
    my @params = $p ? @$p : ();

    # key based on table and fields we are inserting
    my $key = "$table." . join( '.', @$f );
    my ( $query, $sql, $sth );

    if ( $sth_map->{$key} ) {
        $sth = $sth_map->{$key};
    }
    else {
        $query
            = "INSERT INTO $table ("
            . join( ',', @$f )
            . ") values ("
            . join( ',', map {'?'} @$f ) . ") ;";

        $self->_debug($query);
        $sth = $self->{dbh}->prepare($query);

        # cache the handle for next time
        $sth_map->{$key} = $sth;
    }
    my $rv = $sth->execute(@params);

    return { row_count => $rv, error => 0 };
}

# -----------------------------------------------------------------------------

sub _delete_db_record {
    my $self = shift;
    my ( $table, $q, $v ) = @_;
    my $query = "DELETE FROM $table $q ;";

    # run the delete and don't fetch results
    my $resp = $self->_query_db( $query, $v, 1 );
    return $resp;
}

# -----------------------------------------------------------------------------
# as all the indexes are constructued the same, lets have a helper
sub _create_index_str {
    my ( $table, $field ) = @_;

    return sprintf( "CREATE INDEX %s_%s_idx on %s(%s) ;",
        $table, $field, $table, $field );
}

# -----------------------------------------------------------------------------
sub _create_sqlite_table {
    my $self = shift;
    my ($table) = @_;
    $self->_debug("Creating SQLite tables");

    # set WAL mode rather than the default DELETE as its faster
    try { $self->{dbh}->do("PRAGMA journal mode = WAL;"); } catch {};

    my $sql = "CREATE TABLE $table (
        counter         INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        id              VARCHAR(128) NOT NULL UNIQUE,
        queue_name      VARCHAR(128) NOT NULL,
        msg_type        VARCHAR(8),
        persist         BOOLEAN DEFAULT 0,
        added           TIMESTAMP DEFAULT current_timestamp,
        processed       BOOLEAN DEFAULT 0,
        processor       VARCHAR(128),
        process_start   TIMESTAMP,
        processing_time FLOAT,
        process_failure SMALLINT DEFAULT 0,
        data            TEXT   ) ;";

    $self->_debug($sql);
    try { $self->{dbh}->do($sql); } catch {};

}

# -----------------------------------------------------------------------------
sub _create_postgres_table {
    my $self = shift;
    my ($table) = @_;
    $self->_debug("Creating PostgreSQL tables");

    # big/serial creates an auto incrementing column in PostgreSQL
    my $sql = "CREATE TABLE $table (
        counter         BIGSERIAL PRIMARY KEY UNIQUE,
        id              VARCHAR(128) NOT NULL UNIQUE,
        queue_name      VARCHAR(128) NOT NULL,
        msg_type        VARCHAR(8),
        persist         BOOLEAN DEFAULT 0,
        added           TIMESTAMP WITH TIME ZONE DEFAULT now(),
        processed       SMALLINT DEFAULT 0,
        processor       VARCHAR(128),
        process_start   TIMESTAMP,
        processing_time FLOAT,
        process_failure SMALLINT DEFAULT 0,
        data            TEXT  ) ;";

    $self->_debug($sql);
    try { $self->{dbh}->do($sql); } catch {};
}

# -----------------------------------------------------------------------------
sub _create_mysql_table {
    my $self = shift;
    my ($table) = @_;
    $self->_debug("Creating MySQL tables");

    my $sql = "CREATE TABLE $table (
        counter         INT NOT NULL PRIMARY KEY AUTO_INCREMENT UNIQUE,
        id              VARCHAR(128) NOT NULL UNIQUE,
        queue_name      VARCHAR(128) NOT NULL,
        msg_type        VARCHAR(8),
        persist         BOOLEAN DEFAULT 0,
        added           TIMESTAMP DEFAULT current_timestamp,
        processed       SMALLINT DEFAULT 0,
        processor       VARCHAR(128),
        process_start   TIMESTAMP,
        processing_time FLOAT,
        process_failure SMALLINT DEFAULT 0,
        data            TEXT  ) ;";

    $self->_debug($sql);
    try { $self->{dbh}->do($sql); } catch {};

}

# -----------------------------------------------------------------------------
# create all the tables and indexes
sub _create_tables {
    my $self = shift;
    my $sql;
    my $table = $self->{prefix} . '_queue';

    # as the checking for tables and indexes is fraught with issues
    # over multiple databases its easier to not print the errors and
    # catch the creation failures and ignore them!
    my $p = $self->{dbh}->{PrintError};
    $self->{dbh}->{PrintError} = 0;

    # I am assuming either table does not exist then nor does the
    # other and we should create both
    if ( $self->_db_type() eq 'SQLite' ) {
        $self->_create_sqlite_table($table);
    }
    elsif ( $self->_db_type() eq 'Pg' ) {
        $self->_create_postgres_table($table);
    }
    elsif ( $self->_db_type() eq 'mysql' ) {
        $self->_create_mysql_table($table);
    }
    else {
        die "Unhandled database type " . $self->_db_type();
    }

    foreach my $field (
        qw/counter id added queue_name msg_type persist processed process_failure/
        )
    {
        my $sql = _create_index_str( $table, $field );

        $self->_debug($sql);
        try { $self->{dbh}->do($sql); } catch {};
    }

    # restore the PrintError setting
    $self->{dbh}->{PrintError} = $p;
}

# -----------------------------------------------------------------------------
# _add
# Add some data into a named queue. Could be a task or a chatter mesg
# * This does not handle wildcard queues *

sub _add {
    state $uuid = Data::UUID->new();
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "_add accepts a hash or a hashref of parameters";
        return 0;
    }

    # to keep what was here before the change to the parameters
    my $qname    = $params->{queue};
    my $msg_type = $params->{type};
    my $persist  = $params->{persist};
    my $data     = $params->{data};

    if ( ref($data) ne 'HASH' ) {
        warn "_add data parameter must be a hashref";
        return 0;
    }
    my $status = 0;
    my $resp;
    if ( !$qname || !$data ) {
        my $err = "Missing queue name or data";
        $self->_debug($err);
        warn $err;
        return $status;
    }
    if ( $qname =~ /\*/ ) {
        my $err = "Bad queue name, cannot contain '*'";
        $self->_debug($err);
        warn $err;
        return $status;
    }

    try {
        my $json_str = encode_json($data);

      # we manage the id's for the queue entries as we cannot depend
      # on a common SQL method of adding a record and getting its uniq ID back

        my $message_id = $uuid->create_b64();
        $resp = $self->_insert_db(
            $self->{prefix} . '_queue',
            [qw(id queue_name added data msg_type persist)],
            [   $message_id, $qname,
                strftime( "%Y-%m-%d %H:%M:%S", localtime() ),
                $json_str, $msg_type, $persist
            ]
        );

        $status = $message_id if ( !$resp->{error} );
    }
    catch {
        my $e = $@;
        warn $e;
    };

    return $status;
}

# -----------------------------------------------------------------------------

=head2 add

Add task data into a named queue. This creates a 'task' that needs to be processed.

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

    # save some application audit data
    $queue->add(
        queue => 'app_start',
        data => {
            ip => 12.12.12.12, session_id => 12324324345, client_id => 248296432984,
            appid => 2, app_name => 'twitter'
        },
    ) ;

* This does not handle wildcard queues *

=head3  queue

name of the queue

=head3 data

data to store against the queue, can be a scalar, hashref or arrayref

=cut

sub add {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "add accepts a hash or a hashref of parameters";
        return 0;
    }
    $params->{type}    = MSG_TASK;
    $params->{persist} = 0;

    return $self->_add($params);
}

# -----------------------------------------------------------------------------
# try and find a match for the qname, replace SQL wildcard with perl ones

sub _valid_qname {
    my $self = shift;
    my ($qname) = @_;

    # update queue list
    $self->list_queues();

    $qname =~ s/%/*/g;
    my $wild = ( $qname =~ /\*/ ) ? 1 : 0;

    my $match = 0;
    foreach my $q ( keys %{ $self->{_queue_list} } ) {
        if ( ( $wild && $q =~ $qname ) || $self->{_queue_list}->{$qname} ) {
            $match++;
            last;
        }
    }

    return $match;
}

# -----------------------------------------------------------------------------

=head2 process

process up to 100 tasks from the name queue(s)

a reference to the queue object is passed to the callback along with the name of
the queue and the record that is to be procssed.

If the callback returns a non-zero value then the record will be marked as processed.
If the callback returns a zero value, then the processing is assumed to have failed
and the failure count will be incremented by 1. If the failue count matches our
maximum allowed limit then the item will not be available for any further processing.

    sub processing_callback {
        my ( $queue, $qname, $record ) = @_;

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
    $queue->process( queue => '/celestial/*', count => 5, callback => \&processing_callback) ;

=cut

sub process {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "process accepts a hash or a hashref of parameters";
        return 0;
    }

    my $processed_count = 0;
    my $qname           = $params->{queue};

    # if the queue does not exist
    return 0 if ( !$self->_valid_qname($qname) );

    # switch to SQL wildcard
    $qname =~ s/\*/%/g;

    $params->{count} ||= 1;
    die __PACKAGE__ . " process requires a callback function"
        if ( !$params->{callback} || ref( $params->{callback} ) ne 'CODE' );

    if ( $params->{count} > MAX_PROCESS_ITEMS ) {
        warn "Reducing process count from $params->{count} to "
            . MAX_PROCESS_ITEMS;
        $params->{count} = MAX_PROCESS_ITEMS;
    }

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
            ORDER BY added ASC
            LIMIT ?;", $self->{prefix}
    );
    my $ids
        = $self->_query_db( $sql, [ $qname, MSG_TASK, $params->{count} ] );
    my @t;
    foreach my $row ( @{ $ids->{rows} } ) {
        push @t, "'$row->{id}'";
    }

    # if there are no items to update, return
    return $processed_count if ( !scalar(@t) );
    my $id_list = join( ',', @t );

    # mark items that I am going to process
    my $update = "SET processor=?
            WHERE id IN ( $id_list) AND processed = 0 ;";
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $update, [ $self->_processor() ] );
    return $processed_count if ( !$resp->{row_count} );

    # refetch the list to find out which ones we are going to process,
    # in case another system was doing things at the same time
    $sql = sprintf(
        "SELECT * FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND processor = ?
            AND process_failure = 0
            AND msg_type = ?
            ORDER BY added ASC
            LIMIT ?;", $self->{prefix}
    );
    my $info = $self->_query_db( $sql,
        [ $qname, $self->_processor(), MSG_TASK, $params->{count} ] );

    foreach my $row ( @{ $info->{rows} } ) {

        # unpack the data
        $row->{data} = decode_json( $row->{data} );
        my $state   = 0;
        my $start   = strftime( "%Y-%m-%d %H:%M:%S", localtime() );
        my $st      = [gettimeofday];
        my $invalid = 0;
        my $elapsed;
        try {
            $state = $params->{callback}->( $self, $qname, $row );
        }
        catch {
            warn "process: error in callback $@";
            $invalid++;
        };
        $elapsed = tv_interval($st);

        if ($invalid) {

            # if the callback was invalid then we should not mark this
            # as a process failure just clear the processor
            $update = "SET processor=?, WHERE id = ? AND processed = 0 ;";
            $info   = $self->_update_db( $self->{prefix} . "_queue",
                $update, [ '', $row->{id} ] );
        }
        elsif ($state) {

            # show we have processed it
            $update
                = "SET processed=1, process_start=?, processing_time=?  WHERE id = ? AND processed = 0 ;";
            $info = $self->_update_db( $self->{prefix} . "_queue",
                $update, [ $start, $elapsed, $row->{id} ] );
            $processed_count++;
        }
        else {
            # mark the failure
            $update
                = "SET process_failure=1, processing_time=? WHERE id = ? AND processed = 0 ;";
            $info = $self->_update_db( $self->{prefix} . "_queue",
                $update, [ $elapsed, $row->{id} ] );
        }
    }

    return $processed_count;
}

# -----------------------------------------------------------------------------

=head2 process_failures

process up to 100 tasks from the queue
a refrence to the queue object is passed to the callback along with the name of the queue
and the record that is to be procssed. As these are failures we are not interested
in an value of the callback function.

    sub processing_failure_callback {
        my ( $queue, $qname, $record ) = @_;

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
        callback => \&processing_failure_callback
    ) ;

    # again we can use wildcards here for queue names

    # add things to different queues, but with a common root
    $queue->add( queue => '/celestial/stars', data => { list: [ "sun", "alpha centuri"]}) ;
    $queue->add( queue => '/celestial/planets', data => { list: [ "moon", "pluto", "mars"]}) ;
    # process, obviously 'moon' will fail our planet processing
    $queue->process(
        queue => 'queue_name',
        count => 5,
        callback => \&processing_callback
    ) ;

    # process all the 'celestial' bodies queues for failures - probably will just have the moon in it
    $queue->process_failures(
        queue => '/celestial/*',
        count => 5,
        callback => \&processing_failure_callback
    ) ;

=cut

sub process_failures {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "process_failures accepts a hash or a hashref of parameters";
        return 0;
    }

    my $qname = $params->{queue};

    my $processed_count = 0;

    # switch to SQL wildcard
    $qname =~ s/\*/%/g;

    return 0 if ( !$self->_valid_qname($qname) );

    $params->{count} ||= 1;
    die __PACKAGE__ . " process requires a callback function"
        if ( !$params->{callback} || ref( $params->{callback} ) ne 'CODE' );

    if ( $params->{count} > MAX_PROCESS_ITEMS ) {
        warn "Reducing process_failures count from $params->{count} to"
            . MAX_PROCESS_ITEMS;
        $params->{count} = MAX_PROCESS_ITEMS;
    }

    # get list of IDs we can process
    my $sql = sprintf(
        "SELECT id FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND process_failure = 1
            AND msg_type = ?
            ORDER BY added ASC
            LIMIT ?;", $self->{prefix}
    );
    my $ids
        = $self->_query_db( $sql, [ $qname, MSG_TASK, $params->{count} ] );
    my @t;
    foreach my $row ( @{ $ids->{rows} } ) {
        push @t, "'$row->{id}'";
    }

    # if there are no items to update, return
    return $processed_count if ( !scalar(@t) );
    my $id_list = join( ',', @t );

    # mark items that I am going to process
    my $update = "SET processor=?
            WHERE id IN ( $id_list) AND processed = 0 ;";
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $update, [ $self->_processor() ] );
    return $processed_count if ( !$resp->{row_count} );

    # refetch the list to find out which ones we are going to process,
    # in case another system was doing things at the same time
    $sql = sprintf(
        "SELECT * FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND processor = ?
            AND process_failure = 1
            AND msg_type = ?
            ORDER BY added ASC
            LIMIT ?;", $self->{prefix}
    );
    my $info = $self->_query_db( $sql,
        [ $qname, $self->_processor(), MSG_TASK, $params->{count} ] );

    foreach my $row ( @{ $info->{rows} } ) {

        # unpack the data
        $row->{data} = decode_json( $row->{data} );

        my $state = 0;
        try {
            $state = $params->{callback}->( $self, $qname, $row );
        }
        catch {
            warn "process_failures: error in callback $@";
        };

      # we don't do anything else with the record, we assume that the callback
      # function will have done something like delete it or re-write it
    }

    return $processed_count;
}

# -----------------------------------------------------------------------------

=head2 queue_size

get the count of unprocessed TASK items in the queue

    my $count = $queue->queue_size( queue => 'queue_name') ;
    say "there are $count unprocessed items in the queue" ;

    # queue size can manage wildcards
    $queue->queue_size( queue => '/celestial/*') ;

=cut

sub queue_size {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "queue_size accepts a hash or a hashref of parameters";
        return 0;
    }
    my ($qname) = $params->{queue};

    # switch to SQL wildcard
    $qname =~ s/\*/%/g;

    my $sql = sprintf(
        "SELECT count(*) as count FROM %s_queue
            WHERE queue_name LIKE ?
            AND processed = 0
            AND process_failure = 0
            AND msg_type = ? ;", $self->{prefix}
    );
    my $resp = $self->_query_db( $sql, [ $qname, MSG_TASK ] );

    return $resp->{row_count} ? $resp->{rows}->[0]->{count} : 0;
}

# -----------------------------------------------------------------------------

=head2 list_queues

obtains a list of all the queues used by this database

    my $qlist = $queue->list_queues() ;
    foreach my $q (@$qlist) {
        say $q ;
    }

=cut

sub list_queues {
    my $self = shift;
    my %ques;

    my $result = $self->_query_db(
        sprintf( 'SELECT DISTINCT queue_name FROM %s_queue;',
            $self->{prefix} )
    );

    if ( !$result->{error} ) {
        %ques = map { $_->{queue_name} => 1 } @{ $result->{rows} };
    }

    $self->_set_queue_list( \%ques );

    return [ keys %ques ];
}

# -----------------------------------------------------------------------------

=head2 stats

obtains stats about the task data in the queue, this may be time/processor intensive
so use with care!

provides counts of unprocessed, processed, failures
max process_failure, avg process_failure, earliest_added, latest_added,
min_data_size, max_data_size, avg_data_size, total_records
avg_elapsed, max_elapsed, min_elapsed

    my $stats = $queue->stats( queue => 'queue_name') ;
    say "processed $stats->{processed}, failures $stats->{failure}, unprocessed $stats->{unprocessed}" ;

    # for all matching wildcard queues
    my $all_stats = $queue->stats( queue => '/celestial/*') ;

=cut

sub stats {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "stats accepts a hash or a hashref of parameters";
        return {};
    }
    my ($qname) = $params->{queue};
    my %all_stats = ();

    # update queue list
    $self->list_queues();

    # switch to SQL wildcard
    $qname =~ s/%/*/g;

    # work through all the queues and only count that match our qname
    foreach my $q ( keys %{ $self->{_queue_list} } ) {
        next if ( !$self->_valid_qname($q) );
        next if ( ( $qname =~ /\*/ && $qname !~ $q ) || $qname ne $q );

        # queue_size also calls list_queues, so we don't need to do it!
        $all_stats{unprocessed} += $self->queue_size( queue => $q);

        my $sql = sprintf(
            "SELECT count(*) as count
            FROM %s_queue
            WHERE queue_name = ?
            AND msg_type = ?
            AND processed = 1 ;", $self->{prefix}
        );
        my $resp = $self->_query_db( $sql, [ $q, MSG_TASK ] );
        $all_stats{processed} += $resp->{rows}->[0]->{count} || 0;

        $sql = sprintf(
            "SELECT count(*) as count FROM %s_queue
            WHERE queue_name = ?
            AND processed = 0
            AND msg_type = ?
            AND process_failure = 1 ;", $self->{prefix}
        );
        $resp = $self->_query_db( $sql, [ $q, MSG_TASK ] );
        $all_stats{failures} += $resp->{rows}->[0]->{count} || 0;
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
            AND msg_type = ? ;", $self->{prefix}
    );
    my $resp = $self->_query_db( $sql, [ $qname, MSG_TASK ] );

    foreach my $k ( keys %{ $resp->{rows}->[0] } ) {
        if ( $k =~ /_added/ ) {

        }
        else {
            $all_stats{$k} += $resp->{rows}->[0]->{$k} || "0";
        }
    }

    # number of records in the table
    $all_stats{total_records}
        = ( $all_stats{processed}   // 0 )
        + ( $all_stats{unprocessed} // 0 )
        + ( $all_stats{failures}    // 0 );
    $all_stats{total_records} ||= '0';

    # make sure these things have a zero value so calculations don't fail
    foreach my $f (
        qw( unprocessed  processed  failures
        max process_failure avg process_failure  earliest_added latest_added
        min_data_size  max_data_size avg_data_size total_records
        total_records min_proc max_proc avg_proc)
        )
    {
        $all_stats{$f} ||= '0';
    }

    return \%all_stats;
}

# -----------------------------------------------------------------------------

=head2 delete_record

delete a single task record from the queue
requires a data record which contains infomation we will use to determine the record

may be used in processing callback functions

    sub processing_callback {
        my ( $queue, $qname, $record ) = @_;

        # lets remove records before 2013
        if( $record->{added) < '2013-01-01') {
            $queue->delete_record( $record) ;
        }
        return 1 ;
    }

* This does not handle wildcard queues *

=cut

sub delete_record {
    my $self = shift;
    my ($data) = @_;

    my $sql = "WHERE id = ?
        AND queue_name = ?
        AND msg_type = ?";
    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        $sql, [ $data->{id}, $data->{queue_name}, MSG_TASK ] );

    return $resp->{row_count};
}

# -----------------------------------------------------------------------------

=head2 reset_record

clear failure flag from a failed task record
requires a data record which contains infomation we will use to determine the record

may be used in processing callback functions

    sub processing_callback {
        my ( $queue, $qname, $record ) = @_;

        # allow partially failed (and failed) records to be processed
        if( $record->{process_failure) {
            $queue->reset_record( $record) ;
        }
        return 1 ;
    }

* This does not handle wildcard queues *

=cut

sub reset_record {
    my $self = shift;
    my ($data) = @_;

    my $sql = "SET process_failure=0
        WHERE id = ?
        AND queue_name = ?
        AND processed=0
        AND process_failure > 0
        AND msg_type = ?";
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $sql, [ $data->{id}, $data->{queue_name}, MSG_TASK ] );

    return $resp->{row_count};
}

# -----------------------------------------------------------------------------

=head2 publish

Publish some chatter data into a named queue.

arguments

    queue   - the name of the queue to publish a chatter to
    data    - hashref of data to be stored

optional arguments

    persist - 0|1 flag that this message is to be the most recent persistent one

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

    # keep track of a bit of info
    $queue->publish( queue => 'app_log',
        data => {
            ip => 12.12.12.12, session_id => 12324324345, client_id => 248296432984,
            appid => 2, app_name => 'twitter'
        }
    ) ;

* This does not handle wildcard queues *

=cut

sub publish {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "publish accepts a hash or a hashref of parameters";
        return 0;
    }
    $params->{type} = MSG_CHATTER;

    # make sure this is a zero or one value
    $params->{persist} = defined $params->{persist};

    return $self->_add($params);
}

# -----------------------------------------------------------------------------
# find the most recent persistent item
# queue is the only parameter, returns arrayref of items

sub _recent_persist {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "_recent_persist accepts a hash or a hashref of parameters";
        return [];
    }
    my $qname = $params->{queue};
    my @data;

    # if the queue does not exist
    return [] if ( !$self->_valid_qname($qname) );

    # switch to SQL wildcard
    $qname =~ s/\*/%/g;

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
            GROUP BY queue_name
            ORDER BY queue_name;", $self->{prefix}, $self->{prefix}
    );

    # there should only be one persist item
    my $result = $self->_query_db( $sql, [ $qname, MSG_CHATTER, 1 ] );

    foreach my $row ( @{ $result->{rows} } ) {
        $row->{data} = decode_json( $row->{data} );    # unpack the data
        push @data, $row;
    }

    return \@data;
}

# -----------------------------------------------------------------------------
# get chatter data (ordered by datetime added) after a unix time
# queue is the only parameter,
# returns arrayref of items

sub _recent_chatter {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "_recent_chatter accepts a hash or a hashref of parameters";
        return [];
    }

    my $qname = $params->{queue};
    my @data;

    # if the queue does not exist
    return [] if ( !$self->_valid_qname($qname) );

    # switch to SQL wildcard
    $qname =~ s/\*/%/g;

    my $result;
    my $sql;

    if ( $params->{counter} ) {
        $sql = sprintf(
            "SELECT * FROM %s_queue
                    WHERE queue_name LIKE ?
                    AND msg_type = ?
                    AND counter > ?
                    GROUP BY queue_name
                    ORDER BY counter;", $self->{prefix}
        );

        $result = $self->_query_db( $sql,
            [ $qname, MSG_CHATTER, $params->{counter} ] );

    }
    else {
        # check by date
        $sql = sprintf(
            "SELECT * FROM %s_queue
                    WHERE queue_name LIKE ?
                    AND msg_type = ?
                    AND added >= ?
                    ORDER BY counter;", $self->{prefix}
        );

        $result = $self->_query_db( $sql,
            [ $qname, MSG_CHATTER, $params->{after} // 0 ] );
    }

    foreach my $row ( @{ $result->{rows} } ) {
        $row->{data} = decode_json( $row->{data} );    # unpack the data
        push @data, $row;
    }

    return \@data;
}

# -----------------------------------------------------------------------------

=head2 subscribe

Subscribe to a named queue with a callback.

arguments

    queue    - the name of the queue to listen to, wildcards allowed
    callback - function to handle any matced events

optional arguments

    after   - unix time after which to listen for events, defaults to now,
            if set will skip persistent item checks
    persist - include the most recent persistent item, if using a wild card, this
            will match all the queues and could find multiple persistent items

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;

    # keep track of a bit of info
    $queue->subscribe( queue => 'app_logs/*', callback => \&handler) ;
    $queue->listen() ;

=cut

sub subscribe {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "subscribe accepts a hash or a hashref of parameters";
        return 0;
    }

    if ( !$params->{queue} ) {
        warn "subscribe needs a queue name to listen to";
        return 0;
    }

    if ( ref( $params->{callback} ) ne 'CODE' ) {
        warn "subscribe needs a callback handler to send events to";
        return 0;
    }

    # add to our current subscriptions

    if ( $params->{after} ) {

        # we cannot get recent persist item if they want to check after a date
        $params->{persist} = 0;
    }

    if ( !defined $params->{after} ) {
        $params->{after} = strftime( "%Y-%m-%d %H:%M:%S", localtime() );
    }
    elsif ( $params->{after} =~ /^\d+$/ ) {
        $params->{after}
            = strftime( "%Y-%m-%d %H:%M:%S", localtime( $params->{after} ) );
    }
    elsif ( $params->{after} !~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ ) {
        warn(
            "this does not look like a datetime value I can use: '$params->{after}'"
        );
        $params->{after} = strftime( "%Y-%m-%d %H:%M:%S", localtime() );
    }

    $self->{subscriptions}->{ $params->{queue} } = {
        callback => $params->{callback},

        # when do we want events from
        after    => $params->{after},
        persist  => $params->{persist},
        ev_count => 0,
        counter  => 0
    };
}

# -----------------------------------------------------------------------------

=head2 listen

Listen to all subcribed channels. Loops forever unless told to stop.
If there are any persistent messages, this will be passed to the callbacks first.

optional arguments

    events - minimum number of events to listen for, stop after this many,
            may stop after more - this is across ALL the subscriptions
    datetime - unix epoch time when to stop listening, ie based on time()

returns
    number of chatter events actually passed to ALL the handlers

    my $queue = App::Basis::Queue->new( dbh => $dbh) ;
    $queue->subscribe( '/logs/*', \&handler) ;
    $queue->listen() ;    # listening  forever

=cut

sub listen {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "listen accepts a hash or a hashref of parameters";
        return 0;
    }

    if ( !keys %{ $self->{subscriptions} } ) {
        warn "you have not subscribed to any queues";
        return 0;
    }

    $self->{ev_count} = 0;

    # clean things up before we listen
    foreach my $qmatch ( sort keys %{ $self->{subscriptions} } ) {
        my $subs = $self->{subscriptions}->{$qmatch};
        $subs->{counter}  = 0;
        $subs->{ev_count} = 0;
    }

    # loop forever unless there is a reason to stop
    my $started = 0;
    while (1) {

        foreach my $qmatch ( sort keys %{ $self->{subscriptions} } ) {
            my $subs = $self->{subscriptions}->{$qmatch};

            # we may not want the most recent persistent record
            next if ( !$started && !$subs->{persist} );

            my $items;
            if ( !$started ) {
                $items = $self->_recent_persist( queue => $qmatch );
            }
            else {
                $items = $self->_recent_chatter(
                    queue   => $qmatch,
                    after   => $subs->{after},
                    counter => $subs->{counter},
                );
            }

            my $state;
            foreach my $row ( @{$items} ) {

                $subs->{ev_count}++;    # count matches for this queue
                $self->{ev_count}++;    # and overall
                try {
                    # qmatch is the name of the queue matcher
                    $state = $subs->{callback}->( $self, $qmatch, $row );
                    if ( $row->{added} gt $subs->{after} ) {
                        $subs->{after} = $row->{added};
                    }
                    if ( $row->{counter} > $subs->{counter} ) {
                        $subs->{counter} = $row->{counter};
                    }
                }
                catch {
                    warn "listen: error in callback $@";
                };
            }
        }
        $started = 1;
            last
                if ( $params->{events}
                && $self->{ev_count} > $params->{events} );
            last
                if ( $params->{datetime}
                && time() > $params->{datetime} );

        # wait a bit to allow the queues to fillup
        sleep( $self->{listen_delay} );
    }

    return $self->{ev_count};
}

# -----------------------------------------------------------------------------

=head2 unsubscribe

Unsubscribe from a named queue.

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

sub unsubscribe {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "unsubscribe accepts a hash or a hashref of parameters";
        return 0;
    }

    if ( $params->{queue} ) {

        # does not matter if the queue name does not exist!
        delete $self->{subscriptions}->{ $params->{queue} };
    }
}

# -----------------------------------------------------------------------------

=head2 purge_tasks

purge will remove all processed task items and failures (process_failure >= 5).
These are completely removed from the database

    my $before = $queue->stats( queue => 'queue_name', before => '2015-11-24') ;
    $queue->purge_tasks( queue => 'queue_name') ;
    my $after = $queue->stats( queue  => 'queue_name') ;

    say "removed " .( $before->{total_records} - $after->{total_records}) ;


    before is optional and will default to 'now'

=cut

sub purge_tasks {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "purge_tasks accepts a hash or a hashref of parameters";
        return 0;
    }

    my ($qname) = $params->{queue};

    # SQL wildcard replace
    $qname =~ s/\*/%/g;

    if ( !defined $params->{before} ) {
        $params->{before} = strftime( "%Y-%m-%d %H:%M:%S", localtime() );
    }
    elsif ( $params->{before} =~ /^\d+$/ ) {
        $params->{before}
            = strftime( "%Y-%m-%d %H:%M:%S", localtime( $params->{before} ) );
    }
    elsif ( $params->{before} !~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ ) {
        warn(
            "this does not look like a datetime value I can use: '$params->{before}'"
        );
        $params->{before} = strftime( "%Y-%m-%d %H:%M:%S", localtime() );
    }

    my $sql = "WHERE queue_name LIKE ?
        AND processed = 1
        OR process_failure = 1
        AND msg_type = ?
        AND added <= ?";

    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        $sql, [ $qname, MSG_TASK, $params->{before} ] );

    # return the number of items deleted
    return $resp->{row_count};
}

# -----------------------------------------------------------------------------

=head2 purge_chatter

purge will remove all chatter messages.
These are completely removed from the database

    my $del = $queue->purge_chatter( queue => 'queue_name', before => '2015-11-24') ;

    say "removed $del messages" ;

    before is optional and will default to 'now'

=cut

sub purge_chatter {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "purge_chatter accepts a hash or a hashref of parameters";
        return 0;
    }

    my ($qname) = $params->{queue};

    # SQL wildcard replace
    $qname =~ s/\*/%/g;

    my $sql = "WHERE queue_name LIKE ?
        AND processed = 1
        OR process_failure = 1
        AND msg_type = ?
        AND added <= ?";
    my $sql_args = [ $qname, MSG_CHATTER, $params->{before} ];

    if ( defined $params->{counter} ) {
        my $sql = "WHERE queue_name LIKE ?
        AND processed = 1
        OR process_failure = 1
        AND msg_type = ?
        AND counter <= ?";
        my $sql_args = [ $qname, MSG_CHATTER, $params->{counter} ];

    }
    else {
        if ( !defined $params->{before} ) {
            $params->{before} = strftime( "%Y-%m-%d %H:%M:%S", localtime() );
        }
        elsif ( $params->{before} =~ /^\d+$/ ) {
            $params->{before} = strftime( "%Y-%m-%d %H:%M:%S",
                localtime( $params->{before} ) );
        }
        elsif ( $params->{before} !~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/ )
        {
            warn(
                "this does not look like a datetime value I can use: '$params->{before}'"
            );
            $params->{before} = strftime( "%Y-%m-%d %H:%M:%S", localtime() );
        }
    }

    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        $sql, $sql_args );

    # return the number of items deleted
    return $resp->{row_count};
}

# -----------------------------------------------------------------------------

=head2 remove_queue

remove a queue and all of its records (task and chatter)

    $queue->remove_queue( queue => 'queue_name') ;
    my $after = $queue->list_queues() ;
    # convert list into a hash for easier checking
    my %a = map { $_ => 1} @after ;
    say "queue removed" if( !$q->{queue_name}) ;

* This does not handle wildcard queues *

=cut

sub remove_queue {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "remove_queue accepts a hash or a hashref of parameters";
        return 0;
    }

    my ($qname) = $params->{queue};

    # SQL wildcard replace
    $qname =~ s/\*/%/g;

    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        "WHERE queue_name LIKE ?", [$qname] );
    return $resp->{success};
}

# -----------------------------------------------------------------------------

=head2 reset_failures

clear any process_failure values from all unprocessed task items

    my $before = $queue->stats( queue => 'queue_name') ;
    $queue->reset_failures( queue => 'queue_name') ;
    my $after = $queue->stats( queue => 'queue_name') ;

    say "reset " .( $after->{unprocessed} - $before->{unprocessed}) ;

=cut

sub reset_failures {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "reset_failures accepts a hash or a hashref of parameters";
        return 0;
    }

    my $qname = $params->{queue};

    # SQL wildcard replace
    $qname =~ s/\*/%/g;

    my $sql = "SET process_failure=0";
    $sql .= " WHERE queue_name LIKE ?
        AND process_failure = 1
        AND msg_type = ?";
    my $resp = $self->_update_db( $self->{prefix} . "_queue",
        $sql, [ $qname, MSG_TASK ] );

    return $resp->{row_count} ? $resp->{row_count} : 0;
}

# -----------------------------------------------------------------------------

=head2 remove_failures

permanently delete task failures from the database

    $queue->remove_failues( queue => 'queue_name') ;
    my $stats = $queue->stats( queue => 'queue_name') ;
    say "failues left " .( $stats->{failures}) ;

=cut

sub remove_failures {
    my $self = shift;
    my $params = @_ % 2 ? shift : {@_};

    if ( ref($params) ne 'HASH' ) {
        warn "remove_failures accepts a hash or a hashref of parameters";
        return 0;
    }

    my ($qname) = $params->{queue};

    # SQL wildcard replace
    $qname =~ s/\*/%/g;

    my $sql  = "WHERE process_failure = 1 AND msg_type = ?";
    my $resp = $self->_delete_db_record( $self->{prefix} . "_queue",
        $sql, [MSG_TASK] );

    return $resp->{row_count};
}

# -----------------------------------------------------------------------------

=head2 remove_tables

If you never need to use the database again, it can be completely removed

    $queue_>remove_tables() ;

=cut

sub remove_tables {
    my $self = shift;

    my $sql = sprintf( 'DROP TABLE %s_queue;', $self->{prefix} );
    $self->_debug($sql);
    $self->{dbh}->do($sql);
}

# -----------------------------------------------------------------------------

1;
