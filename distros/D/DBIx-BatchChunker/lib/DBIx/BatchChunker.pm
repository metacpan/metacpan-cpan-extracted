package DBIx::BatchChunker;

our $AUTHORITY = 'cpan:GSG';
our $VERSION   = '0.93';

use Moo;

use CLDR::Number;

use Types::Standard        qw( Any Item Str Num Bool Undef ArrayRef HashRef CodeRef InstanceOf Tuple Maybe Optional slurpy );
use Types::Common::Numeric qw( PositiveInt PositiveOrZeroInt PositiveOrZeroNum );
use Type::Utils;

use Data::Float;
use List::Util        1.33 (qw( min max sum any first ));  # has any/all/etc.
use POSIX                   qw( ceil );
use Scalar::Util            qw( blessed weaken );
use Term::ProgressBar 2.14;                          # with silent option
use Time::HiRes             qw( time sleep );

use namespace::clean;  # don't export the above

our $DB_MAX_ID = Data::Float::max_integer;  # used for progress_past_max

=encoding utf8

=head1 NAME

DBIx::BatchChunker - Run large database changes safely

=head1 VERSION

version 0.93

=head1 SYNOPSIS

    use DBIx::BatchChunker;

    my $account_rs = $schema->resultset('Account')->search({
        account_type => 'deprecated',
    });

    my %params = (
        chunk_size  => 5000,
        target_time => 5,

        rs      => $account_rs,
        id_name => 'account_id',

        coderef => sub { $_[1]->delete },
        sleep   => 1,
        debug   => 1,

        process_name     => 'Deleting deprecated accounts',
        process_past_max => 1,
    );

    # EITHER:
    # 1) Automatically construct and execute the changes:

    DBIx::BatchChunker->construct_and_execute(%params);

    # OR
    # 2) Manually construct and execute the changes:

    my $batch_chunker = DBIx::BatchChunker->new(%params);

    $batch_chunker->calculate_ranges;
    $batch_chunker->execute;

=head1 DESCRIPTION

This utility class is for running a large batch of DB changes in a manner that doesn't
cause huge locks, outages, and missed transactions.  It's highly flexible to allow for
many different kinds of change operations, and dynamically adjusts chunks to its
workload.

It works by splitting up DB operations into smaller chunks within a loop.  These chunks
are transactionalized, either naturally as single-operation bulk work or by the loop
itself.  The full range is calculated beforehand to get the right start/end points.
A L<progress bar|/Progress Bar Attributes> will be created to let the deployer know the
processing status.

There are two ways to use this class: call the automatic constructor and executor
(L</construct_and_execute>) or manually construct the object and call its methods. See
L</SYNOPSIS> for examples of both.

B<DISCLAIMER:> You should not rely on this class to magically fix any and all locking
problems the DB might experience just because it's being used.  Thorough testing and
best practices are still required.

=head2 Processing Modes

This class has several different modes of operation, depending on what was passed to
the constructor:

=head3 DBIC Processing

If both L</rs> and L</coderef> are passed, a chunk ResultSet is built from the base
ResultSet, to add in a C<BETWEEN> clause, and the new ResultSet is passed into the
coderef.  The coderef should run some sort of active ResultSet operation from there.

An L</id_name> should be provided, but if it is missing it will be looked up based on
the primary key of the ResultSource.

If L</single_rows> is also enabled, then each chunk is wrapped in a transaction and the
coderef is called for each row in the chunk.  In this case, the coderef is passed a
Result object instead of the chunk ResultSet.

Note that whether L</single_rows> is enabled or not, the coderef execution is encapsulated
in DBIC's retry logic, so any failures will re-connect and retry the coderef.  Because of
this, any changes you make within the coderef should be idempotent, or should at least be
able to skip over any already-processed rows.

=head3 Active DBI Processing

If an L</stmt> (DBI statement handle args) is passed without a L</coderef>, the statement
handle is merely executed on each iteration with the start and end IDs.  It is assumed
that the SQL for the statement handle contains exactly two placeholders for a C<BETWEEN>
clause.  For example:

    my $update_stmt = q{
    UPDATE
        accounts a
        JOIN account_updates au USING (account_id)
    SET
        a.time_stamp = au.time_stamp
    WHERE
        a.account_id BETWEEN ? AND ? AND
        a.time_stamp != au.time_stamp
    });

The C<BETWEEN> clause should, of course, match the IDs being used in the loop.

The statement is ran with L</dbi_connector> for retry protection.  Therefore, the
statement should also be idempotent.

=head3 Query DBI Processing

If both a L</stmt> and a L</coderef> are passed, the statement handle is prepared and
executed.  Like the L</Active DBI Processing> mode, the SQL for the statement should
contain exactly two placeholders for a C<BETWEEN> clause.  Then the C<$sth> is passed to
the coderef.  It's up to the coderef to extract data from the executed statement handle,
and do something with it.

If C<single_rows> is enabled, each chunk is wrapped in a transaction and the coderef is
called for each row in the chunk.  In this case, the coderef is passed a hashref of the
row instead of the executed C<$sth>, with lowercase alias names used as keys.

Note that in both cases, the coderef execution is encapsulated in a L<DBIx::Connector::Retry>
call to either C<run> or C<txn> (using L</dbi_connector>), so any failures will
re-connect and retry the coderef.  Because of this, any changes you make within the
coderef should be idempotent, or should at least be able to skip over any
already-processed rows.

=head3 DIY Processing

If a L</coderef> is passed but neither a C<stmt> nor a C<rs> are passed, then the
multiplier loop does not touch the database.  The coderef is merely passed the start and
end IDs for each chunk.  It is expected that the coderef will run through all database
operations using those start and end points.

It's still valid to include L</min_stmt>, L</max_stmt>, and/or L</count_stmt> in the
constructor to enable features like L<max ID recalculation|/process_past_max> or
L<chunk resizing|/min_chunk_percent>.

=head3 TL;DR Version

    $stmt                             = Active DBI Processing
    $stmt + $coderef                  = Query DBI Processing  | $bc->$coderef($executed_sth)
    $stmt + $coderef + single_rows=>1 = Query DBI Processing  | $bc->$coderef($row_hashref)
    $rs   + $coderef                  = DBIC Processing       | $bc->$coderef($chunk_rs)
    $rs   + $coderef + single_rows=>1 = DBIC Processing       | $bc->$coderef($result)
            $coderef                  = DIY Processing        | $bc->$coderef($start, $end)

=head1 ATTRIBUTES

See the L</METHODS> section for more in-depth descriptions of these attributes and their
usage.

=head2 DBIC Processing Attributes

=head3 rs

A L<DBIx::Class::ResultSet>. This is used by all methods as the base ResultSet onto which
the DB changes will be applied.  Required for DBIC processing.

=cut

has rs => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Class::ResultSet'],
    required => 0,
);

=head3 rsc

A L<DBIx::Class::ResultSetColumn>. This is only used to override L</rs> for min/max
calculations.  Optional.

=cut

has rsc => (
    is        => 'ro',
    isa       => InstanceOf['DBIx::Class::ResultSetColumn'],
    required  => 0,
);

=head3 dbic_retry_opts

A hashref of DBIC retry options.  These options control how retry protection works within
DBIC.  So far, there are two supported options:

    max_attempts  = Number of times to retry
    retry_handler = Coderef that returns true to continue to retry or false to re-throw
                    the last exception

The default is to use DBIC's built-in retry options, the same way L<DBIx::Class::Storage::DBI/dbh_do>
does it, which will retry once if the DB connection was disconnected.  If you specify any
options, even a blank hashref, BatchChunker will fill in a default C<max_attempts> of 10,
and an always-true C<retry_handler>.  This is similar to L<DBIx::Connector::Retry>'s
defaults.

Under the hood, these are options that are passed to the as-yet-undocumented
L<DBIx::Class::Storage::BlockRunner>.  The C<retry_handler> has access to the same
BlockRunner object (passed as its only argument) and its methods/accessors, such as C<storage>,
C<failed_attempt_count>, and C<last_exception>.

=cut

has dbic_retry_opts => (
    is       => 'ro',
    isa      => HashRef,
    required => 0,
    lazy     => 1,
    builder  => 1,
);

sub _build_dbic_retry_opts {
    my $self = shift;

    return {
        # the default from DBIC
        retry_handler => sub {
            $_[0]->failed_attempt_count == 1 && !$_[0]->storage->connected
        },
    };
}

sub _dbic_block_runner {
    my ($self, $method, $coderef) = @_;

    # A very light wrapper around BlockRunner.  No need to load BlockRunner, since DBIC
    # loads it in before us if we're using this method.
    DBIx::Class::Storage::BlockRunner->new(
        # in case they are not defined with a custom dbic_retry_opts
        max_attempts  => 10,
        retry_handler => sub { 1 },

        # never overrides the important ones below
        %{ $self->dbic_retry_opts },

        storage  => $self->dbic_storage,
        wrap_txn => ($method eq 'txn' ? 1 : 0),
    )->run($coderef);
}

=head2 DBI Processing Attributes

=head3 dbi_connector

A L<DBIx::Connector::Retry> object.  Instead of L<DBI> statement handles, this is the
recommended way for BatchChunker to interface with the DBI, as it handles retries on
failures.  The connection mode used is whatever default is set within the object.

Required for DBI Processing, unless L</dbic_storage> is specified.

=cut

has dbi_connector => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Connector::Retry'],
    required => 0,
);

=head3 dbic_storage

A DBIC storage object, as an alternative for L</dbi_connector>.  There may be times when
you want to run plain DBI statements, but are still using DBIC.  In these cases, you
don't have to create a L<DBIx::Connector::Retry> object to run those statements.

This uses a BlockRunner object for retry protection, so the options in
L</dbic_retry_opts> would apply here.

Required for DBI Processing, unless L</dbi_connector> is specified.

=cut

has dbic_storage => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Class::Storage::DBI'],
    required => 0,
);

=head3 min_stmt

=head3 max_stmt

SQL statement strings or an arrayref of parameters for L<DBI/selectrow_array>.

When executed, these statements should each return a single value, either the minimum or
maximum ID that will be affected by the DB changes.  These are used by
L</calculate_ranges>.  Required if using either type of DBI Processing.

=cut

my $SQLStringOrSTHArgs_type = Type::Utils::declare(
    name       => 'SQLStringOrSTHArgs',
    # Allow an SQL string, an optional hashref/undef, and any number of strings/undefs
    parent     => Tuple->parameterize(Str, Optional[Maybe[HashRef]], slurpy ArrayRef[Maybe[Str]]),
    coercion   => sub { $_ = [ $_ ] if Str->check($_); $_ },
    message    => sub { 'Must be either an SQL string or an arrayref of parameters for $sth creation (SQL + hashref/undef + binds)' },
);

has min_stmt => (
    is       => 'ro',
    isa      => $SQLStringOrSTHArgs_type,
    required => 0,
    coerce   => 1,
);

has max_stmt => (
    is       => 'ro',
    isa      => $SQLStringOrSTHArgs_type,
    required => 0,
    coerce   => 1,
);

=head3 stmt

A SQL statement string or an arrayref of parameters for L<DBI/prepare> + binds.

If using L</Active DBI Processing> (no coderef), this is a L<do-able|DBI/do> statement
(usually DML like C<INSERT/UPDATE/DELETE>).  If using L</Query DBI Processing> (with
coderef), this is a passive DQL (C<SELECT>) statement.

In either case, the statement should contain C<BETWEEN> placeholders, which will be
executed with the start/end ID points.  If there are already bind placeholders in the
arrayref, then make sure the C<BETWEEN> bind points are last on the list.

Required for DBI Processing.

=cut

has stmt => (
    is       => 'ro',
    isa      => $SQLStringOrSTHArgs_type,
    required => 0,
    coerce   => 1,
);

=head3 count_stmt

A C<SELECT COUNT> SQL statement string or an arrayref of parameters for
L<DBI/selectrow_array>.

Like L</stmt>, it should contain C<BETWEEN> placeholders.  In fact, the SQL should look
exactly like the L</stmt> query, except with C<COUNT(*)> instead of the column list.

Used only for L</Query DBI Processing>.  Optional, but recommended for
L<chunk resizing|/min_chunk_percent>.

=cut

has count_stmt => (
    is       => 'ro',
    isa      => $SQLStringOrSTHArgs_type,
    required => 0,
    coerce   => 1,
);

=head2 Progress Bar Attributes

=head3 progress_bar

The progress bar used for all methods.  This can be specified right before the method
call to override the default used for that method.  Unlike most attributes, this one
is read-write, so it can be switched on-the-fly.

Don't forget to remove or switch to a different progress bar if you want to use a
different one for another method:

    $batch_chunker->progress_bar( $calc_pb );
    $batch_chunker->calculate_ranges;
    $batch_chunker->progress_bar( $loop_pb );
    $batch_chunker->execute;

All of this is optional.  If the progress bar isn't specified, the method will create
a default one.  If the terminal isn't interactive, the default L<Term::ProgressBar> will
be set to C<silent> to naturally skip the output.

=cut

has progress_bar => (
    is       => 'rw',
    isa      => InstanceOf['Term::ProgressBar'],
);

=head3 progress_name

A string used by L</execute> to assist in creating a progress bar.  Ignored if
L</progress_bar> is already specified.

This is the preferred way of customizing the progress bar without having to create one
from scratch.

=cut

has progress_name => (
    is       => 'rw',
    isa      => Str,
    required => 0,
    lazy     => 1,
    default  => sub {
        my $rs = shift->rs;
        'Processing'.($rs ? ' '.$rs->result_source->name : '');
    },
);

=head3 cldr

A L<CLDR::Number> object.  English speakers that use a typical C<1,234.56> format would
probably want to leave it at the default.  Otherwise, you should provide your own.

=cut

has cldr => (
    is       => 'rw',
    isa      => InstanceOf['CLDR::Number'],
    required => 0,
    lazy     => 1,
    default  => sub { CLDR::Number->new(locale => 'en') },
);

=head3 debug

Boolean.  If turned on, displays timing stats on each chunk, as well as total numbers.

=cut

has debug => (
    is       => 'rw',
    isa      => Bool,
    required => 0,
    default  => 0,
);

=head2 Common Attributes

=head3 id_name

The column name used as the iterator in the processing loops.  This should be a primary
key or integer-based (indexed) key, tied to the L<resultset|/rs>.

Optional.  Used mainly in DBIC processing.  If not specified, it will look up
the first primary key column from L</rs> and use that.

This can still be specified for other processing modes to use in progress bars.

=cut

has id_name => (
    is       => 'rw',
    isa      => Str,
    required => 0,
    trigger  => \&_fix_id_name,
);

sub _fix_id_name {
    my ($self, $id_name) = @_;
    return if !$id_name || $id_name =~ /\./ || !$self->rs;  # prevent an infinite trigger loop
    $self->id_name( $self->rs->current_source_alias.".$id_name" );
}

=head3 coderef

The coderef that will be called either on each chunk or each row, depending on how
L</single_rows> is set.  The first input is always the BatchChunker object.  The rest
vary depending on the processing mode:

    $stmt + $coderef                  = Query DBI Processing  | $bc->$coderef($executed_sth)
    $stmt + $coderef + single_rows=>1 = Query DBI Processing  | $bc->$coderef($row_hashref)
    $rs   + $coderef                  = DBIC Processing       | $bc->$coderef($chunk_rs)
    $rs   + $coderef + single_rows=>1 = DBIC Processing       | $bc->$coderef($result)
            $coderef                  = DIY Processing        | $bc->$coderef($start, $end)

The loop does not monitor the return values from the coderef.

Required for all processing modes except L</Active DBI Processing>.

=cut

has coderef => (
    is       => 'ro',
    isa      => CodeRef,
    required => 0,
);

=head3 chunk_size

The amount of rows to be processed in each loop.

Default is 1000 rows.  This figure should be sized to keep per-chunk processing time
at around 5 seconds.  If this is too large, rows may lock for too long.  If it's too
small, processing may be unnecessarily slow.

=cut

has chunk_size => (
    is       => 'ro',
    isa      => PositiveInt,
    required => 0,
    default  => 1000,
);

=head3 target_time

The target runtime (in seconds) that chunk processing should strive to achieve, not
including L</sleep>.  If the chunk processing times are too high or too low, this will
dynamically adjust L</chunk_size> to try to match the target.

B<Turning this on does not mean you should ignore C<chunk_size>!>  If the starting chunk
size is grossly inaccurate to the workload, you could end up with several chunks in the
beginning causing long-lasting locks before the runtime targeting reduces them down to a
reasonable size.

Default is 5 seconds.  Set this to zero to turn off runtime targeting.  (This was
previously defaulted to off prior to v0.92, and set to 15 in v0.92.)

=cut

has target_time => (
    is       => 'ro',
    isa      => PositiveOrZeroNum,
    required => 0,
    default  => 5,
);

=head3 sleep

The number of seconds to sleep after each chunk.  It uses L<Time::HiRes>'s version, so
fractional numbers are allowed.

Default is 0, which is fine for most operations.  But, it is highly recommended to turn
this on (say, 1 to 5 seconds) for really long one-off DB operations, especially if a lot
of disk I/O is involved.  Without this, there's a chance that the slaves will have a hard
time keeping up, and/or the master won't have enough processing power to keep up with
standard load.

This will increase the overall processing time of the loop, so try to find a balance
between the two.

=cut

has 'sleep' => (
    is       => 'ro',
    isa      => PositiveOrZeroNum,
    required => 0,
    default  => 0,
);

=head3 process_past_max

Boolean that controls whether to check past the L</max_id> during the loop.  If the loop
hits the end point, it will run another maximum ID check in the DB, and adjust C<max_id>
accordingly.  If it somehow cannot run a DB check (no L</rs> or L</max_stmt> available,
for example), the last chunk will check all the way to C<$DB_MAX_ID>.

This is useful if the entire table is expected to be processed, and you don't want to
miss any new rows that come up between L</calculate_ranges> and the end of the loop.

Turned off by default.

B<NOTE:> If your RDBMS has a problem with a number as high as whatever L<max_integer|Data::Float/max_integer>
reports, you may want to set the C<$DB_MAX_ID> global variable in this module to
something lower.

=cut

has process_past_max => (
    is       => 'ro',
    isa      => Bool,
    required => 0,
    default  => 0,
);

=head3 single_rows

Boolean that controls whether single rows are passed to the L</coderef> or the chunk's
ResultSets/statement handle is passed.

Since running single-row operations in a DB is painfully slow (compared to bulk
operations), this also controls whether the entire set of coderefs are encapsulated into
a DB transaction.  Transactionalizing the entire chunk brings the speed, and atomicity,
back to what a bulk operation would be.  (Bulk operations are still faster, but you can't
do anything you want in a single DML statement.)

Used only by L</DBIC Processing> and L</Query DBI Processing>.

=cut

has single_rows => (
    is       => 'ro',
    isa      => Bool,
    required => 0,
    default  => 0,
);

=head3 min_chunk_percent

The minimum row count, as a percentage of L</chunk_size>.  This value is actually
expressed in decimal form, i.e.: between 0 and 1.

This value will be used to determine when to process, skip, or expand a block, based on
a count query.  The default is C<0.5> or 50%, which means that it will try to expand the
block to a larger size if the row count is less than 50% of the chunk size.  Zero-sized
blocks will be skipped entirely.

This "chunk resizing" is useful for large regions of the table that have been deleted, or
when the incrementing ID has large gaps in it for other reasons.  Wasting time on
numerical gaps that span millions can slow down the processing considerably, especially
if L</sleep> is enabled.

If this needs to be disabled, set this to 0.  The maximum chunk percentage does not have
a setting and is hard-coded at C<< 100% + min_chunk_percent >>.

If DBIC processing isn't used, L</count_stmt> is also required to enable chunk resizing.

=cut

has min_chunk_percent => (
    is       => 'ro',
    isa      => Type::Utils::declare(
        name       => 'PositiveZeroToOneNum',
        parent     => Num,
        constraint => sub { $_ >= 0 && $_ <= 1 },
        inlined    => sub { undef, qq($_ >= 0 && $_ <= 1) },
        message    => sub { 'Must be a number between 0 and 1' },
    ),
    required => 0,
    default  => 0.5,
);

=head3 min_id

=head3 max_id

Used by L</execute> to figure out the main start and end points.  Calculated by
L</calculate_ranges>.

Manually setting this is not recommended, as each database is different and the
information may have changed between the DB change development and deployment.  Instead,
use L</calculate_ranges> to fill in these values right before running the loop.

=cut

has min_id => (
    is       => 'rw',
    isa      => PositiveOrZeroInt,
);

has max_id => (
    is       => 'rw',
    isa      => PositiveOrZeroInt,
);

=head2 Private Attributes

=head3 _loop_state

These variables exist solely for the processing loop.  They should be cleared out after
use.  Most of the complexity is needed for chunk resizing.

=over

=item timer

Timer for debug messages.  Always spans the time between debug messages.

=item start

The real start ID that the loop is currently on.  May continue to exist within iterations
if chunk resizing is trying to find a valid range.  Otherwise, this value will become
undef when a chunk is finally processed.

=item end

The real end ID that the loop is currently looking at.  This is always redefined at the
beginning of the loop.

=item prev_end

Last "processed" value of C<end>.  This also includes skipped blocks.  Used in C<start>
calculations and to determine if the end of the loop has been reached.

=item max_end

The maximum ending ID.  This will be C<$DB_MAX_ID> if L</process_past_max> is set.

=item last_range

A hashref of keys used for the bisecting of one block.  Cleared out after a block has
been processed or skipped.

=item last_timings

An arrayref of hashrefs, containing data for the previous 5 runs.  This data is used for
runtime targeting.

=item multiplier_range

The range (in units of L</chunk_size>) between the start and end IDs.  This starts at 1
(at the beginning of the loop), but may expand or shrink depending on chunk count checks.
Resets after block processing.

=item multiplier_step

Determines how fast multiplier_range increases, so that chunk resizing happens at an
accelerated pace.  Speeds or slows depending on what kind of limits the chunk count
checks are hitting.  Resets after block processing.

=item checked_count

A check counter to make sure the chunk resizing isn't taking too long.  After ten checks,
it will give up, assuming the block is safe to process.

=item chunk_size

The I<current> chunk size, which might be adjusted by runtime targeting.

=item chunk_count

Records the results of the C<COUNT(*)> query for chunk resizing.

=item prev_check

A short string recording what happened during the last chunk resizing check.  Exists
purely for debugging purposes.

=item prev_runtime

The number of seconds the previously processed chunk took to run, not including sleep
time.

=item progress_bar

The progress bar being used in the loop.  This may be different than L</progress_bar>,
since it could be auto-generated.

=back

=cut

has _loop_state => (
    is       => 'rw',
    isa      => HashRef,
    required => 0,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_loop_state',
    clearer  => '_clear_loop_state',
);

sub _build_loop_state {
    my $self = shift;

    my $start = $self->min_id;

    return {
        timer    => time,
        start    => $start,
        end      => $start + $self->chunk_size - 1,
        prev_end => $start - 1,
        max_end  => ($self->process_past_max ? $DB_MAX_ID : $self->max_id),

        last_range       => {},
        last_timings     => [],
        multiplier_range => 0,
        multiplier_step  => 1,
        checked_count    => 0,
        chunk_size       => $self->chunk_size,
        chunk_count      => undef,
        prev_check       => '',
        prev_runtime     => undef,

        progress_bar     => undef,
    };
}

around BUILDARGS => sub {
    my $next  = shift;
    my $class = shift;

    my %args = @_ == 1 ? %{ $_[0] } : @_;

    # Auto-building of rsc and id_name can be a weird dependency dance, so it's better to
    # handle it here.
    my ($rsc, $rs, $id_name) = @args{qw< rsc rs id_name >};
    if    ($rsc && !$id_name) {
        $args{id_name} = $rsc->{_as};
    }
    elsif (!$rsc && $id_name && $rs) {
        $args{rsc}     = $rs->get_column( $args{id_name} );
    }
    elsif (!$rsc && !$id_name && $rs) {
        $args{id_name} = ($rs->result_source->primary_columns)[0];
        $args{rsc}     = $rs->get_column( $args{id_name} );
    }
    $rsc = $args{rsc};

    # Auto-add dbic_storage, if available
    if (!$args{dbic_storage} && ($rs || $rsc)) {
        $args{dbic_storage} = $rs ? $rs->result_source->storage : $rsc->_resultset->result_source->storage;
    }

    # Find something to use as a dbi_connector, if it doesn't already exist
    my @old_attrs = qw< sth min_sth max_sth count_sth >;
    my @new_attrs = map { my $k = $_; $k =~ s/sth$/stmt/; $k } @old_attrs;
    my $example_key = first { $args{$_} } @old_attrs;
    if ($example_key && !$args{dbi_connector}) {
        warn join "\n",
            'The sth/*_sth options are now considered legacy usage in DBIx::BatchChunker.  Because there is no',
            'way to re-acquire the password, any attempt to reconnect will fail.  Please use dbi_connector and',
            'stmt/*_stmt instead for reconnection support.',
            ''
        ;

        # NOTE: There was a way to monkey-patch _connect to use $dbh->clone, but I've considered it
        # too intrusive of a solution to use.  Better to demand that the user switch to the new
        # attributes, but have something that still works in most cases.

        # Attempt to build some sort of Connector object
        require DBIx::Connector::Retry;
        my $dbh = $args{$example_key}->{Database};

        my $conn = DBIx::Connector::Retry->new(
            connect_info => [
                join(':', 'dbi', $dbh->{Driver}{Name}, $dbh->{Name}),
                $dbh->{Username},
                '',  # XXX: Can't acquire the password
                # Sane %attr defaults on the off-chance that it actually re-connects
                { AutoCommit => 1, RaiseError => 1 },
            ],

            # Do not disconnect on DESTROY.  The $dbh might still be used post-run.
            disconnect_on_destroy => 0,
        );

        # Pretend $conn->_connect was called and store our pre-existing $dbh
        $conn->{_pid} = $$;
        $conn->{_tid} = threads->tid if $INC{'threads.pm'};
        $conn->{_dbh} = $dbh;
        $conn->driver;

        $args{dbi_connector} = $conn;
    }

    # Handle legacy options for sth/*_sth
    foreach my $old_attr (grep { $args{$_} } @old_attrs) {
        my $new_attr = $old_attr;
        $new_attr =~ s/sth$/stmt/;

        my $sth = delete $args{$old_attr};
        $args{$new_attr} ||= [ $sth->{Statement} ];
    }

    # Now check to make sure dbi_connector is available for DBI processing
    die 'DBI processing requires a dbi_connector or dbic_storage attribute!' if (
        !($args{dbi_connector} || $args{dbic_storage}) &&
        (first { $args{$_} } @new_attrs)
    );

    # Other sanity checks
    die 'Range calculations requires one of these attr sets: rsc, rs, or dbi_connector|dbic_storage + min_stmt + max_stmt' unless (
        $args{rsc} ||
        ($args{min_stmt} && $args{max_stmt})
    );

    die 'Block execution requires one of these attr sets: dbi_connector|dbic_storage + stmt, rs + coderef, or coderef' unless (
        $args{stmt} ||
        ($args{rs} && $args{coderef}) ||
        $args{coderef}
    );

    $class->$next( %args );
};

sub BUILD {
    my $self = shift;
    # Make sure id_name gets fixed at the right time
    $self->_fix_id_name( $self->id_name );
}

=head1 CONSTRUCTORS

See L</ATTRIBUTES> for information on what can be passed into these constructors.

=head2 new

    my $batch_chunker = DBIx::BatchChunker->new(...);

A standard object constructor. If you use this constructor, you will need to
manually call L</calculate_ranges> and L</execute> to execute the DB changes.

=head2 construct_and_execute

    my $batch_chunker = DBIx::BatchChunker->construct_and_execute(...);

Constructs a DBIx::BatchChunker object and automatically calls
L</calculate_ranges> and L</execute> on it. Anything passed to this method will be passed
through to the constructor.

Returns the constructed object, post-execution.  This is typically only useful if you want
to inspect the attributes after the process has finished.  Otherwise, it's safe to just
ignore the return and throw away the object immediately.

=cut

sub construct_and_execute {
    my $class     = shift;
    my $db_change = $class->new(@_);

    $db_change->calculate_ranges;
    $db_change->execute;

    return $db_change;
}

=head1 METHODS

=head2 calculate_ranges

    my $batch_chunker = DBIx::BatchChunker->new(
        rsc      => $account_rsc,    # a ResultSetColumn
        ### OR ###
        rs       => $account_rs,     # a ResultSet
        id_name  => 'account_id',    # can be looked up if not provided
        ### OR ###
        dbi_connector => $conn,      # DBIx::Connector::Retry object
        min_stmt      => $min_stmt,  # a SQL statement or DBI $sth args
        max_stmt      => $max_stmt,  # ditto

        ### Optional but recommended ###
        id_name      => 'account_id',  # will also be added into the progress bar title
        chunk_size   => 20_000,        # default is 1000

        ### Optional ###
        progress_bar => $progress,     # defaults to a 2-count 'Calculating ranges' bar

        # ...other attributes for execute...
    );

    my $has_data_to_process = $batch_chunker->calculate_ranges;

Given a L<DBIx::Class::ResultSetColumn>, L<DBIx::Class::ResultSet>, or L<DBI> statement
argument set, this method calculates the min/max IDs of those objects.  It fills in the
L</min_id> and L</max_id> attributes, based on the ID data, and then returns 1.

If either of the min/max statements don't return any ID data, this method will return 0.

=cut

sub calculate_ranges {
    my $self = shift;

    my $column_name = $self->id_name || '';
    $column_name =~ s/^\w+\.//;

    my $progress = $self->progress_bar || Term::ProgressBar->new({
        name   => 'Calculating ranges'.($column_name ? " for $column_name" : ''),
        count  => 2,
        ETA    => 'linear',
        silent => !(-t *STDERR && -t *STDIN),  # STDERR is what {fh} is set to use
    });

    # Actually run the statements
    my ($min_id, $max_id);
    if ($self->rsc) {
        $self->_dbic_block_runner( run => sub {
            # In case the sub is retried
            $progress->update(0);

            $min_id = $self->rsc->min;
            $progress->update(1);

            $max_id = $self->rsc->max;
            $progress->update(2);
        });
    }
    elsif ($self->dbic_storage) {
        $self->_dbic_block_runner( run => sub {
            my $dbh = $self->dbic_storage->dbh;

            # In case the sub is retried
            $progress->update(0);

            ($min_id) = $dbh->selectrow_array(@{ $self->min_stmt });
            $progress->update(1);

            ($max_id) = $dbh->selectrow_array(@{ $self->max_stmt });
            $progress->update(2);
        });
    }
    else {
        $self->dbi_connector->run(sub {
            my $dbh = $_;

            # In case the sub is retried
            $progress->update(0);

            ($min_id) = $dbh->selectrow_array(@{ $self->min_stmt });
            $progress->update(1);

            ($max_id) = $dbh->selectrow_array(@{ $self->max_stmt });
            $progress->update(2);
        });
    }

    # Set the ranges and return
    return 0 unless defined $min_id && $max_id;

    $self->min_id( int $min_id );
    $self->max_id( int $max_id );

    return 1;
}

=head2 execute

    my $batch_chunker = DBIx::BatchChunker->new(
        # ...other attributes for calculate_ranges...

        dbi_connector => $conn,          # DBIx::Connector::Retry object
        stmt          => $do_stmt,       # INSERT/UPDATE/DELETE $stmt with BETWEEN placeholders
        ### OR ###
        dbi_connector => $conn,          # DBIx::Connector::Retry object
        stmt          => $select_stmt,   # SELECT $stmt with BETWEEN placeholders
        count_stmt    => $count_stmt,    # SELECT COUNT $stmt to be used for min_chunk_percent; optional
        coderef       => $coderef,       # called code that does the actual work
        ### OR ###
        rs      => $account_rs,          # base ResultSet, which gets filtered with -between later on
        id_name => 'account_id',         # can be looked up if not provided
        coderef => $coderef,             # called code that does the actual work
        ### OR ###
        coderef => $coderef,             # DIY database work; just pass the $start/$end IDs

        ### Optional but recommended ###
        sleep             => 0.25, # number of seconds to sleep each chunk; defaults to 0
        process_past_max  => 1,    # use this if processing the whole table
        single_rows       => 1,    # does $coderef get a single $row or the whole $chunk_rs / $stmt
        min_chunk_percent => 0.25, # minimum row count of chunk size percentage; defaults to 0.5 (or 50%)
        target_time       => 5,    # target runtime for dynamic chunk size scaling; default is 5 seconds

        progress_name => 'Updating Accounts',  # easier than creating your own progress_bar

        ### Optional ###
        progress_bar     => $progress,  # defaults to "Processing $source_name" bar
        debug            => 1,          # displays timing stats on each chunk
    );

    $batch_chunker->execute if $batch_chunker->calculate_ranges;

Applies the configured DB changes in chunks.  Runs through the loop, processing a
statement handle, ResultSet, and/or coderef as it goes.  Each loop iteration processes a
chunk of work, determined by L</chunk_size>.

The L</calculate_ranges> method should be run first to fill in L</min_id> and L</max_id>.
If either of these are missing, the function will assume L</calculate_ranges> couldn't
find them and warn about it.

More details can be found in the L</Processing Modes> and L</ATTRIBUTES> sections.

=cut

sub execute {
    my $self = shift;

    my $count;
    if (defined $self->min_id && defined $self->max_id) {
        $count = $self->max_id - $self->min_id + 1;
    }

    # Fire up the progress bar
    my $progress = $self->progress_bar || Term::ProgressBar->new({
        name   => $self->progress_name,
        count  => $count || 1,
        ETA    => 'linear',
        silent => !(-t *STDERR && -t *STDIN),  # STDERR is what {fh} is set to use
    });

    unless ($count) {
        $progress->message('No chunks; nothing to process...');
        return;
    }

    if ($self->debug) {
        $progress->message(
            sprintf "(%s total chunks; %s total rows)",
                map { $self->cldr->decimal_formatter->format($_) } ( ceil($count / $self->chunk_size), $count)
        );
    }

    # Loop state setup
    $self->_clear_loop_state;
    my $ls = $self->_loop_state;
    $ls->{progress_bar} = $progress;

    # Da loop
    while ($ls->{prev_end} < $ls->{max_end} || $ls->{start}) {
        $ls->{multiplier_range} += $ls->{multiplier_step};
        $ls->{start}             = $ls->{prev_end} + 1 unless defined $ls->{start};   # this could be already set because of early 'next' calls
        $ls->{end}               = $ls->{start} + $ls->{multiplier_range} * $ls->{chunk_size} - 1;
        $ls->{chunk_count}       = undef;

        next unless $self->_process_past_max_checker;

        # The actual DB processing
        next unless $self->_process_block;

        # Record the time quickly
        $ls->{prev_runtime} = time - $ls->{timer};

        # Give the DB a little bit of breathing room
        sleep $self->sleep if $self->sleep;

        $self->_print_debug_status('processed');
        $self->_increment_progress;
        $self->_runtime_checker;

        # End-of-loop activities (skipped by early next)
        $ls->{start}     = undef;
        $ls->{prev_end}  = $ls->{end};
        $ls->{timer}     = time;

        $ls->{last_range}       = {};
        $ls->{multiplier_range} = 0;
        $ls->{multiplier_step}  = 1;
        $ls->{checked_count}    = 0;
    }
    $self->_clear_loop_state;

    # Keep the finished time from the progress bar, in case there are other loops or output
    unless ($progress->silent) {
        $progress->update( $progress->target );
        print "\n";
    }
}

=head1 PRIVATE METHODS

=head2 _process_block

Runs the DB work and passes it to the coderef.  Its return value determines whether the
block should be processed or not.

=cut

sub _process_block {
    my ($self) = @_;

    my $ls      = $self->_loop_state;
    my $conn    = $self->dbi_connector;
    my $coderef = $self->coderef;
    my $rs      = $self->rs;

    # Figure out if the row count is worth the work
    my $chunk_rs;
    my $count_stmt = $self->count_stmt;
    if ($count_stmt && $self->dbic_storage) {
        $self->_dbic_block_runner( run => sub {
            ($self->_loop_state->{chunk_count}) = $self->dbic_storage->dbh->selectrow_array(
                @$count_stmt,
                (@$count_stmt == 1 ? undef : ()),
                @$ls{qw< start end >},
            );
        });
    }
    elsif ($count_stmt) {
        ($ls->{chunk_count}) = $conn->run(sub {
            $_->selectrow_array(
                @$count_stmt,
                (@$count_stmt == 1 ? undef : ()),
                @$ls{qw< start end >},
            );
        });
    }
    elsif ($rs) {
        $chunk_rs = $rs->search({
            $self->id_name => { -between => [@$ls{qw< start end >}] },
        });

        $self->_dbic_block_runner( run => sub {
            $self->_loop_state->{chunk_count} = $chunk_rs->count;
        });
    }

    return unless $self->_chunk_count_checker;

    # NOTE: Try to minimize the amount of closures by using $self as much as possible
    # inside coderefs.

    # Do the work
    if (my $stmt = $self->stmt) {
        ### Statement handle
        my @prepare_args = @$stmt > 2 ? @$stmt[0..1] : @$stmt;
        my @execute_args = (
            (@$stmt > 2 ? @$stmt[2..$#$stmt] : ()),
            @$ls{qw< start end >},
        );

        if ($self->single_rows && $coderef) {
            # Transactional work
            if ($self->dbic_storage) {
                $self->_dbic_block_runner( txn => sub {
                    $self->_loop_state->{timer} = time;  # reset timer on retries

                    my $sth = $self->dbic_storage->dbh->prepare(@prepare_args);
                    $sth->execute(@execute_args);

                    while (my $row = $sth->fetchrow_hashref('NAME_lc')) { $self->coderef->($self, $row) }
                });
            }
            else {
                $conn->txn(sub {
                    $self->_loop_state->{timer} = time;  # reset timer on retries

                    my $sth = $_->prepare(@prepare_args);
                    $sth->execute(@execute_args);

                    while (my $row = $sth->fetchrow_hashref('NAME_lc')) { $self->coderef->($self, $row) }
                });
            }
        }
        else {
            # Bulk work (or DML)
            if ($self->dbic_storage) {
                $self->_dbic_block_runner( run => sub {
                    $self->_loop_state->{timer} = time;  # reset timer on retries

                    my $sth = $self->dbic_storage->dbh->prepare(@prepare_args);
                    $sth->execute(@execute_args);

                    $self->coderef->($self, $sth) if $self->coderef;
                });
            }
            else {
                $conn->run(sub {
                    $self->_loop_state->{timer} = time;  # reset timer on retries

                    my $sth = $_->prepare(@prepare_args);
                    $sth->execute(@execute_args);

                    $self->coderef->($self, $sth) if $self->coderef;
                });
            }
        }
    }
    elsif ($rs && $coderef) {
        ### ResultSet with coderef

        if ($self->single_rows) {
            # Transactional work
            $self->_dbic_block_runner( txn => sub {
                # reset timer/$rs on retries
                $self->_loop_state->{timer} = time;
                $chunk_rs->reset;

                while (my $row = $chunk_rs->next) { $self->coderef->($self, $row) }
            });
        }
        else {
            # Bulk work
            $self->_dbic_block_runner( run => sub {
                # reset timer/$rs on retries
                $self->_loop_state->{timer} = time;
                $chunk_rs->reset;

                $self->coderef->($self, $chunk_rs);
            });
        }
    }
    else {
        ### Something a bit more free-form

        $self->$coderef(@$ls{qw< start end >});
    }

    return 1;
}

=head2 _process_past_max_checker

Checks to make sure the current endpoint is actually the end, by checking the database.
Its return value determines whether the block should be processed or not.

See L</process_past_max>.

=cut

sub _process_past_max_checker {
    my ($self) = @_;
    my $ls = $self->_loop_state;
    my $progress = $ls->{progress_bar};

    return 1 unless $self->process_past_max;
    return 1 unless $ls->{end} > $self->max_id;

    # No checks for DIY, if they didn't include a max_stmt
    unless ($self->rsc || $self->max_stmt) {
        # There's no way to size this, so skip past the max as one block
        $ls->{end} = $ls->{max_end};
        return 1;
    }

    # Run another MAX check
    $progress->message('Reached end; re-checking max ID') if $self->debug;
    my $new_max_id;
    if (my $rsc = $self->rsc) {
        $self->_dbic_block_runner( run => sub {
            $new_max_id = $rsc->max;
        });
    }
    elsif ($self->dbic_storage) {
        $self->_dbic_block_runner( run => sub {
            ($new_max_id) = $self->dbic_storage->dbh->selectrow_array(@{ $self->max_stmt });
        });
    }
    else {
        ($new_max_id) = $self->dbi_connector->run(sub {
            $_->selectrow_array(@{ $self->max_stmt });
        });
    }
    $ls->{timer} = time;  # the above query shouldn't impact runtimes

    if (!$new_max_id || $new_max_id eq '0E0') {
        # No max: No affected rows to change
        $progress->message('No max ID found; nothing left to process...') if $self->debug;
        $ls->{end} = $ls->{max_end};

        $ls->{prev_check} = 'no max';
        return 0;
    }
    elsif ($new_max_id > $self->max_id) {
        # New max ID
        $progress->message( sprintf 'New max ID set from %u to %u', $self->max_id, $new_max_id ) if $self->debug;
        $self->max_id($new_max_id);
        $progress->target( $new_max_id - $self->min_id + 1 );
        $progress->update( $progress->last_update );
    }
    elsif ($new_max_id == $self->max_id) {
        # Same max ID
        $progress->message( sprintf 'Found max ID %u; same as end', $new_max_id ) if $self->debug;
        $ls->{max_end} = $new_max_id;
    }
    else {
        # Max too low
        $progress->message( sprintf 'Found max ID %u; ignoring...', $new_max_id ) if $self->debug;
        $ls->{max_end} = $self->max_id;
    }

    return 1;
}

=head2 _chunk_count_checker

Checks the chunk count to make sure it's properly sized.  If not, it will try to shrink
or expand the current chunk (in C<chunk_size> increments) as necessary.  Its return value
determines whether the block should be processed or not.

See L</min_chunk_percent>.

This is not to be confused with the L</_runtime_checker>, which adjusts C<chunk_size>
after processing, based on previous run times.

=cut

sub _chunk_count_checker {
    my ($self) = @_;
    my $ls = $self->_loop_state;
    my $progress = $ls->{progress_bar};

    # Chunk sizing is essentially disabled, so bounce out of here
    if ($self->min_chunk_percent <= 0 || !defined $ls->{chunk_count}) {
        $ls->{prev_check} = 'disabled';
        return 1;
    }

    my $chunk_percent = $ls->{chunk_count} / $ls->{chunk_size};
    $ls->{checked_count}++;

    if    ($ls->{chunk_count} == 0 && $self->min_chunk_percent > 0) {
        # No rows: Skip the block entirely, and accelerate the stepping
        $self->_print_debug_status('skipped');

        $self->_increment_progress;
        $ls->{start}     = undef;
        $ls->{prev_end}  = $ls->{end};
        $ls->{timer}     = time;

        $ls->{last_range}       = {};
        $ls->{multiplier_range} = 0;
        $ls->{multiplier_step} *= 2;
        $ls->{checked_count}    = 0;

        $ls->{prev_check} = 'skipped rows';
        return 0;
    }
    elsif ($chunk_percent > 1 + $self->min_chunk_percent) {
        # Too many rows: Backtrack to the previous range and try to bisect
        $self->_print_debug_status('shrunk');

        $ls->{timer} = time;

        # If we have a min/max range, bisect down the middle.  If not, walk back
        # to the previous range and decelerate the stepping, which should bring
        # it to a halfway point from this range and last.
        $ls->{last_range}{max}  = $ls->{multiplier_range} if !defined $ls->{last_range}{max} || $ls->{multiplier_range} < $ls->{last_range}{max};
        $ls->{multiplier_range} = $ls->{last_range}{min} || ($ls->{multiplier_range} - $ls->{multiplier_step});
        $ls->{multiplier_step}  = int( defined $ls->{last_range}{min} ?
            ($ls->{last_range}{max} - $ls->{last_range}{min}) / 2 :
            $ls->{multiplier_step} / 2
        );

        $ls->{prev_check} = 'too many rows';
        return 0;
    }

    # The above two are more important than skipping the count checks.  Better to
    # have too few rows than too many.

    elsif ($ls->{checked_count} > 10) {
        # Checked too many times: Just process it
        $ls->{prev_check} = 'too many checks';
        return 1;
    }
    elsif ($ls->{end} >= $ls->{max_end}) {
        # At the end: Just process it
        $ls->{prev_check} = 'at max_end';
        return 1;
    }
    elsif ($chunk_percent < $self->min_chunk_percent) {
        # Too few rows: Keep the start ID and accelerate towards a better endpoint
        $self->_print_debug_status('expanded');

        $ls->{timer} = time;

        # If we have a min/max range, bisect down the middle.  If not, keep
        # accelerating the stepping.
        $ls->{last_range}{min} = $ls->{multiplier_range} if !defined $ls->{last_range}{min} || $ls->{multiplier_range} > $ls->{last_range}{min};
        $ls->{multiplier_step} = int( defined $ls->{last_range}{max} ?
            ($ls->{last_range}{max} - $ls->{last_range}{min}) / 2 :
            $ls->{multiplier_step} * 2
        );
        $ls->{prev_check} = 'too few rows';
        return 0;
    }

    $ls->{prev_check} = 'nothing wrong';
    return 1;
}

=head2 _runtime_checker

Stores the previously processed chunk's runtime, and then adjusts C<chunk_size> as
necessary.

See L</target_time>.

=cut

sub _runtime_checker {
    my ($self) = @_;
    my $ls = $self->_loop_state;
    return unless $self->target_time;
    return unless $ls->{chunk_size} && $ls->{prev_runtime};  # prevent DIV/0

    my $timings = $ls->{last_timings};

    my $new_timing = {
        runtime     => $ls->{prev_runtime},
        chunk_count => $ls->{chunk_count} || $ls->{chunk_size},
    };
    $new_timing->{chunk_per} = $new_timing->{chunk_count} / $ls->{chunk_size};

    # Rowtime: a measure of how much of the chunk_size actually impacted the runtime
    $new_timing->{rowtime} = $new_timing->{runtime} / $new_timing->{chunk_per};

    # Store the last five processing times
    push @$timings, $new_timing;
    shift @$timings if @$timings > 5;

    # Figure out the averages and adjustment factor
    my $ttl = scalar @$timings;
    my $avg_rowtime   = sum(map { $_->{rowtime} } @$timings) / $ttl;
    my $adjust_factor = $self->target_time / $avg_rowtime;

    my $new_target_chunk_size = $ls->{chunk_size};
    my $adjective;
    if    ($adjust_factor > 1.05) {
        # Too fast: Raise the chunk size

        return unless $ttl >= 5;                                          # must have a full set of timings
        return if any { $_->{runtime} >= $self->target_time } @$timings;  # must ALL have low runtimes

        $new_target_chunk_size *= min(2, $adjust_factor);  # never more than double
        $adjective = 'fast';
    }
    elsif ($adjust_factor < 0.95) {
        # Too slow: Lower the chunk size

        return unless $ls->{prev_runtime} > $self->target_time;  # last runtime must actually be too high

        $new_target_chunk_size *=
            ($ls->{prev_runtime} < $self->target_time * 3) ?
            max(0.5, $adjust_factor) :  # never less than half...
            $adjust_factor              # ...unless the last runtime was waaaay off
        ;
        $new_target_chunk_size = 1 if $new_target_chunk_size < 1;
        $adjective = 'slow';
    }

    $new_target_chunk_size = int $new_target_chunk_size;
    return if $new_target_chunk_size == $ls->{chunk_size};  # either nothing changed or it's too miniscule
    return if $new_target_chunk_size < 1;

    # Print out a debug line, if enabled
    if ($self->debug) {
        # CLDR number formatters
        my $integer = $self->cldr->decimal_formatter;
        my $percent = $self->cldr->percent_formatter;

        $ls->{progress_bar}->message( sprintf(
            "Processing too %s, avg %4s of target time, adjusting chunk size from %s to %s",
            $adjective,
            $percent->format( 1 / $adjust_factor ),
            $integer->format( $ls->{chunk_size} ),
            $integer->format( $new_target_chunk_size ),
        ) );
    }

    # Change it!
    $ls->{chunk_size} = $new_target_chunk_size;
    $ls->{last_timings} = [] if $adjective eq 'fast';  # never snowball too quickly
    return 1;
}

=head2 _increment_progress

Increments the progress bar.

=cut

sub _increment_progress {
    my ($self) = @_;
    my $ls = $self->_loop_state;
    my $progress = $ls->{progress_bar};

    my $so_far = $ls->{end} - $self->min_id + 1;
    $progress->target($so_far+1) if $ls->{end} > $self->max_id;
    $progress->update($so_far);
}

=head2 _print_debug_status

Prints out a standard debug status line, if debug is enabled.  What it prints is
generally uniform, but it depends on the processing action.  Most of the data is
pulled from L</_loop_state>.

=cut

sub _print_debug_status {
    my ($self, $action) = @_;
    return unless $self->debug;

    my $ls    = $self->_loop_state;
    my $sleep = $self->sleep || 0;

    # CLDR number formatters
    my $integer = $self->cldr->decimal_formatter;
    my $percent = $self->cldr->percent_formatter;
    my $decimal = $self->cldr->decimal_formatter(
        minimum_fraction_digits => 2,
        maximum_fraction_digits => 2,
    );

    my $message = sprintf(
        'IDs %6u to %6u %9s, %9s rows found',
        $ls->{start}, $ls->{end}, $action,
        $integer->format( $ls->{chunk_count} ),
    );

    $message .= sprintf(
        ' (%4s of chunk size)',
        $percent->format( $ls->{chunk_count} / $ls->{chunk_size} ),
    ) if $ls->{chunk_count};

    if ($action eq 'processed') {
        $message .= $sleep ?
            sprintf(
                ', %5s+%s sec runtime+sleep',
                $decimal->format( $ls->{prev_runtime} ),
                $decimal->format( $sleep )
            ) :
            sprintf(
                ', %5s sec runtime',
                $decimal->format( $ls->{prev_runtime} ),
            )
        ;
    }

    return $ls->{progress_bar}->message($message);
}

=head1 SEE ALSO

L<DBIx::BulkLoader::Mysql>, L<DBIx::Class::BatchUpdate>, L<DBIx::BulkUtil>

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Grant Street Group

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
