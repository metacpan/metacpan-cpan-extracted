package DBIx::Class::Storage::DBI::mysql::Retryable;

use strict;
use warnings;

use DBI '1.630';
use base qw< DBIx::Class::Storage::DBI::mysql >;

use Algorithm::Backoff::RetryTimeouts;
use Context::Preserve;
use DBIx::ParseError::MySQL;
use List::Util   qw< min max >;
use Scalar::Util qw< blessed >;
use Storable     qw< dclone >;
use Time::HiRes  qw< time sleep >;
use namespace::clean;

# ABSTRACT: MySQL-specific DBIC storage engine with retry support
use version;
our $VERSION = 'v1.0.0'; # VERSION

#pod =head1 SYNOPSIS
#pod
#pod     package MySchema;
#pod
#pod     # Recommended
#pod     DBIx::Class::Storage::DBI::mysql::Retryable->_use_join_optimizer(0);
#pod
#pod     __PACKAGE__->storage_type('::DBI::mysql::Retryable');
#pod
#pod     # Optional settings (defaults shown)
#pod     my $storage_class = 'DBIx::Class::Storage::DBI::mysql::Retryable';
#pod     $storage_class->parse_error_class('DBIx::ParseError::MySQL');
#pod     $storage_class->timer_class('Algorithm::Backoff::RetryTimeouts');
#pod     $storage_class->timer_options({});           # same defaults as the timer class
#pod     $storage_class->aggressive_timeouts(0);
#pod     $storage_class->warn_on_retryable_error(0);
#pod     $storage_class->enable_retryable(1);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This storage engine for L<DBIx::Class> is a MySQL-specific engine that will explicitly
#pod retry on MySQL-specific transient error messages, as identified by L<DBIx::ParseError::MySQL>,
#pod using L<Algorithm::Backoff::RetryTimeouts> as its retry algorithm.  This engine should be
#pod much better at handling deadlocks, connection errors, and Galera node flips to ensure the
#pod transaction always goes through.
#pod
#pod =head2 How Retryable Works
#pod
#pod A DBIC command triggers some sort of connection to the MySQL server to send SQL.  First,
#pod Retryable makes sure the connection C<mysql_*_timeout> values (except C<mysql_read_timeout>
#pod unless L</aggressive_timeouts> is set) are set properly.  (The default settings for
#pod L<RetryTimeouts|Algorithm::Backoff::RetryTimeouts/Typical scenario> will use half of the
#pod maximum duration, with some jitter.)  If the connection was successful, a few C<SET SESSION>
#pod commands for timeouts are sent first:
#pod
#pod     wait_timeout   # only with aggressive_timeouts=1
#pod     lock_wait_timeout
#pod     innodb_lock_wait_timeout
#pod     net_read_timeout
#pod     net_write_timeout
#pod
#pod If the DBIC command fails at any point in the process, and the error is a recoverable
#pod failure (according to the L<error parsing class|DBIx::ParseError::MySQL>), the retry
#pod process starts.
#pod
#pod The timeouts are only checked during the retry handler.  Since DB operations are XS
#pod calls, Perl-style "safe" ALRM signals won't do any good, and the engine won't attempt to
#pod use unsafe ones.  Thus, the engine relies on the server to honor the timeouts set during
#pod each attempt, and will give up if it runs out of time or attempts.
#pod
#pod If the DBIC command succeeds during the process, program flow resumes as normal.  If any
#pod re-attempts happened during the DBIC command, the timeouts are reset back to the original
#pod post-connection values.
#pod
#pod =head1 STORAGE OPTIONS
#pod
#pod =cut

__PACKAGE__->mk_group_accessors('inherited' => qw<
    parse_error_class timer_class
    timer_options aggressive_timeouts
    warn_on_retryable_error enable_retryable
>);

__PACKAGE__->mk_group_accessors('simple' => qw<
    _retryable_timer _retryable_current_timeout
    _retryable_call_type _retryable_exception_prefix
>);

# Set defaults
__PACKAGE__->parse_error_class('DBIx::ParseError::MySQL');
__PACKAGE__->timer_class('Algorithm::Backoff::RetryTimeouts');
__PACKAGE__->timer_options({});
__PACKAGE__->aggressive_timeouts(0);
__PACKAGE__->warn_on_retryable_error(0);
__PACKAGE__->enable_retryable(1);

#pod =head2 parse_error_class
#pod
#pod Class used to parse MySQL error messages.
#pod
#pod Default is L<DBIx::ParseError::MySQL>.  If a different class is used, it must support a
#pod similar interface, especially the L<C<is_transient>|DBIx::ParseError::MySQL/is_transient>
#pod method.
#pod
#pod =head2 timer_class
#pod
#pod Algorithm class used to determine timeout and sleep values during the retry process.
#pod
#pod Default is L<Algorithm::Backoff::RetryTimeouts>.  If a different class is used, it must
#pod support a similar interface, including the dual return of the L<C<failure>|Algorithm::Backoff::RetryTimeouts/failure>
#pod method.
#pod
#pod =head2 timer_options
#pod
#pod Options to pass to the timer algorithm constructor, as a hashref.
#pod
#pod Default is an empty hashref, which would retain all of the defaults of the algorithm
#pod module.
#pod
#pod =head2 aggressive_timeouts
#pod
#pod Boolean that controls whether to use some of the more aggressive, query-unfriendly
#pod timeouts:
#pod
#pod =over
#pod
#pod =item mysql_read_timeout
#pod
#pod Controls the timeout for all read operations.  Since SQL queries in the middle of
#pod sending its first set of row data are still considered to be in a read operation, those
#pod queries could time out during those circumstances.
#pod
#pod If you're confident that you don't have any SQL statements that would take longer than
#pod C<R/2> (or at least returning results before that time), you can turn this option on.
#pod Otherwise, you may experience longer-running statements going into a retry death spiral
#pod until they finally hit the Retryable timeout for good and die.
#pod
#pod =item wait_timeout
#pod
#pod Controls how long the MySQL server waits for activity from the connection before timing
#pod out.  While most applications are going to be using the database connection pretty
#pod frequently, the MySQL default (8 hours) is much much longer than the mere seconds this
#pod engine would set it to.
#pod
#pod =back
#pod
#pod Default is off.  Obviously, this setting only makes sense with L</retryable_timeout>
#pod turned on.
#pod
#pod =head2 warn_on_retryable_error
#pod
#pod Boolean that controls whether to warn on retryable failures, as the engine encounters
#pod them.  Many applications don't want spam on their screen for recoverable conditions, but
#pod this may be useful for debugging or CLI tools.
#pod
#pod Unretryable failures always generate an exception as normal, regardless of the setting.
#pod
#pod This is functionally equivalent to L<DBI/PrintError>, but since L<"RaiseError"|DBI/RaiseError>
#pod is already the DBIC-required default, the former option can't be used within DBI.
#pod
#pod Default is off.
#pod
#pod =head2 enable_retryable
#pod
#pod Boolean that enables the Retryable logic.  This can be turned off to temporarily disable
#pod it, and revert to DBIC's basic "retry once if disconnected" default.  This may be useful
#pod if a process is already using some other retry logic (like L<DBIx::OnlineDDL>).
#pod
#pod Messing with this setting in the middle of a database action would not be wise.
#pod
#pod Default is on.
#pod
#pod =cut

### Backward-compatibility for legacy attributes

sub max_attempts {
    my $self = shift;
    my $opts = $self->timer_options;

    return $opts->{max_attempts} = $_[0] if @_;
    return $opts->{max_attempts} // 8;
}

sub retryable_timeout {
    my $self = shift;
    my $opts = $self->timer_options;

    return $opts->{max_actual_duration} = $_[0] if @_;
    return $opts->{max_actual_duration} // 50;
}

sub disable_retryable {
    my $self = shift;
    $self->enable_retryable( $_[0] ? 0 : 1 ) if @_;
    return $self->enable_retryable ? 0 : 1;
}

#pod =head1 METHODS
#pod
#pod =cut

sub _build_retryable_timer {
    my $self = shift;
    return $self->timer_class->new(
        %{ dclone $self->timer_options }
    );
}

sub _reset_retryable_timeout {
    my $self = shift;

    # Use a temporary timer to get the first timeout value
    my $timeout = $self->_build_retryable_timer->timeout;
    $timeout = 0 if $timeout == -1;
    $self->_retryable_current_timeout($timeout);
}

sub _failed_attempt_count { shift->_retryable_timer->{_attempts} // 0 }

# Constructor
sub new {
    my $self = shift->next::method(@_);

    $self->_reset_retryable_timeout;

    $self;
}

# Return the list of timeout strings to check
sub _timeout_set_list {
    my ($self, $type) = @_;

    my @timeout_set;
    if    ($type eq 'dbi') {
        @timeout_set = (qw< connect write >);
        push @timeout_set, 'read' if $self->aggressive_timeouts;

        @timeout_set = map { "mysql_${_}_timeout" } @timeout_set;
    }
    elsif ($type eq 'session') {
        @timeout_set = (qw< lock_wait innodb_lock_wait net_read net_write >);
        push @timeout_set, 'wait' if $self->aggressive_timeouts;

        @timeout_set = map { "${_}_timeout" } @timeout_set;
    }
    else {
        die "Unknown mysql timeout set: $type";
    }

    return @timeout_set;
}

# Set the timeouts for reconnections by inserting them into the default DBI connection
# attributes.
sub _default_dbi_connect_attributes () {
    my $self = shift;
    return $self->next::method unless $self->_retryable_current_timeout && $self->enable_retryable;

    my $timeout = int( $self->_retryable_current_timeout + 0.5 );

    return +{
        (map {; $_ => $timeout } $self->_timeout_set_list('dbi')),  # set timeouts
        mysql_auto_reconnect => 0,  # do not use MySQL's own reconnector
        %{ $self->next::method },   # inherit the other default attributes
    };
}

# Re-apply the timeout settings above on _dbi_connect_info.  Used after the initial
# connection by the retry handling.
sub _set_dbi_connect_info {
    my $self = shift;
    return unless $self->_retryable_current_timeout && $self->enable_retryable;

    my $timeout = int( $self->_retryable_current_timeout + 0.5 );

    my $info = $self->_dbi_connect_info;

    # Not even going to attempt this one...
    if (ref $info eq 'CODE') {
        warn <<"EOW" unless $ENV{DBIC_RETRYABLE_DONT_SET_CONNECT_SESSION_VARS};

***************************************************************************
Your connect_info is a coderef, which means connection-based MySQL timeouts
cannot be dynamically changed. Under certain conditions, the connection (or
combination of connection attempts) may take longer to timeout than your
current timer settings.

You'll want to revert to a 4-element style DBI argument set, to fully
support the timeout functionality.

To disable this warning, set a true value to the environment variable
DBIC_RETRYABLE_DONT_SET_CONNECT_SESSION_VARS

***************************************************************************
EOW
        return;
}

    my $dbi_attr = $info->[3];
    return unless $dbi_attr && ref $dbi_attr eq 'HASH';

    $dbi_attr->{$_} = $timeout for $self->_timeout_set_list('dbi');
}

# Set session timeouts for post-connection variables
sub _run_connection_actions {
    my $self = shift;
    $self->_set_retryable_session_timeouts;
    $self->next::method(@_);
}

sub _set_retryable_session_timeouts {
    my $self = shift;
    return unless $self->_retryable_current_timeout && $self->enable_retryable;

    my $timeout = int( $self->_retryable_current_timeout + 0.5 );

    # Ironically, we aren't running our own SET SESSION commands with their own
    # BlockRunner protection, since that may lead to infinite stack recursion.  Instead,
    # put it in a basic eval, and do a quick is_transient check.  If it passes, let the
    # next *_do/_do_query call handle it.

    local $@;
    eval {
        my $dbh = $self->_dbh;
        if ($dbh) {
            $dbh->do("SET SESSION $_=$timeout") for $self->_timeout_set_list('session');
        }
    };
    # Protect $@ again, just in case the parser class does something inappropriate
    # with a blessed $error
    if ( my $error = $@ ) {
        die unless do { # bare die for $@ propagation
            local $@;
            $self->parse_error_class->new($error)->is_transient;
        };

        # The error may have been transient, but we might have ran out of retries, anyway
        die if $error =~ m<Failed \w+ coderef: .+, attempts: \d+ / \d+, timer: [\d\.]+ / [\d\.]+ sec, last exception: >;

        warn "Encountered a recoverable error during SET SESSION timeout commands: $error" if $self->warn_on_retryable_error;
    }
}

# Make sure the initial connection call is protected from retryable failures
sub _connect {
    my $self = shift;
    return $self->next::method() unless $self->enable_retryable;
    # next::can here to do mro calculations prior to sending to _blockrunner_do
    return $self->_blockrunner_do( connect => $self->next::can() );
}

#pod =head2 dbh_do
#pod
#pod     my $val = $schema->storage->dbh_do(
#pod         sub {
#pod             my ($storage, $dbh, @binds) = @_;
#pod             $dbh->selectrow_array($sql, undef, @binds);
#pod         },
#pod         @passed_binds,
#pod     );
#pod
#pod This is very much like L<DBIx::Class::Storage::DBI/dbh_do>, except it doesn't require a
#pod connection failure to retry the sub block.  Instead, it will also retry on locks, query
#pod interruptions, and failovers.
#pod
#pod Normal users of DBIC typically won't use this method directly.  Instead, any ResultSet
#pod or Result method that contacts the DB will send its SQL through here, and protect it from
#pod retryable failures.
#pod
#pod However, this method is recommended over using C<< $schema->storage->dbh >> directly to
#pod run raw SQL statements.
#pod
#pod =cut

# Main "doer" method for both dbh_do and txn_do
sub _blockrunner_do {
    my $self       = shift;
    my $call_type  = shift;
    my $run_target = shift;

    # See https://metacpan.org/release/DBIx-Class/source/lib/DBIx/Class/Storage/DBI.pm#L842
    my $args = @_ ? \@_ : [];

    my $target_runner = sub {
        # dbh_do and txn_do have different sub arguments, and _connect shouldn't
        # have a _get_dbh call.
        if    ($call_type eq 'txn_do')  { $run_target->( @$args ); }
        elsif ($call_type eq 'dbh_do')  { $self->$run_target( $self->_get_dbh, @$args ); }
        elsif ($call_type eq 'connect') { $self->$run_target( @$args ); }
        else { die "Unknown call type: $call_type" }
    };

    # Transaction depth short circuit (same as DBIx::Class::Storage::DBI)
    return $target_runner->() if $self->{_in_do_block} || $self->transaction_depth;

    # Given our transaction depth short circuits, we should be at the outermost loop,
    # so it's safe to reset our variables.
    $self->_retryable_timer( $self->_build_retryable_timer );

    my $timeout = $self->_retryable_timer->timeout;
    $timeout = 0 if $timeout == -1;
    $self->_retryable_current_timeout($timeout);
    $self->_retryable_call_type($call_type);

    # We have some post-processing to do, so save the BlockRunner object, and then save
    # the result in a context-sensitive manner.
    my $br = DBIx::Class::Storage::BlockRunner->new(
        storage       => $self,
        wrap_txn      => $call_type eq 'txn_do',

        # This neuters the max_attempts trigger in failed_attempt_count, so that the main check
        # in our retry_handler works as expected.
        max_attempts  => 99999,

        retry_handler => \&_blockrunner_retry_handler,
    );

    return preserve_context {
        $br->run($target_runner);
    }
    after => sub { $self->_reset_timers_and_timeouts };
}

# Our own BlockRunner retry handler
sub _blockrunner_retry_handler {
    my $br   = shift;
    my $self = $br->storage;  # "self" for this module

    my $last_error = $br->last_exception;

    # Record the failure in the timer algorithm (prior to any checks)
    my ($sleep_time, $new_timeout) = $self->_retryable_timer->failure;

    # If it's not a retryable error, stop here
    my $parsed_error = $self->parse_error_class->new($last_error);
    return $self->_reset_and_fail('Exception not transient') unless $parsed_error->is_transient;

    $last_error =~ s/\n.+//s;
    $self->_warn_retryable_error($last_error) if $self->warn_on_retryable_error;

    # Either stop here (because of timeout or max attempts), sleep, or don't
    if    ($sleep_time == -1) { return $self->_reset_and_fail('Out of retries') }
    elsif ($sleep_time)       { sleep $sleep_time;                              }

    if ($new_timeout > 0) {
        # Reset the connection timeouts before we connect again
        $self->_retryable_current_timeout($new_timeout);
        $self->_set_dbi_connect_info;
    }

    # Force a disconnect, but only if the connection seems to be in a broken state
    local $@;
    unless ($parsed_error->error_type eq 'lock') {
        eval { local $SIG{__DIE__}; $self->disconnect };
    }

    # Because BlockRunner calls this unprotected, and because our own _connect is going
    # to hit the _in_do_block short-circuit, we should call this ourselves, in a
    # protected eval, and re-direct any errors as if it was another failed attempt.
    eval { $self->ensure_connected };
    if (my $connect_error = $@) {
        push @{ $br->exception_stack }, $connect_error;
        return _blockrunner_retry_handler($br);
    }

    return 1;
}

sub dbh_do {
    my $self = shift;
    return $self->next::method(@_) unless $self->enable_retryable;
    return $self->_blockrunner_do( dbh_do => @_ );
}

#pod =head2 txn_do
#pod
#pod     my $val = $schema->txn_do(
#pod         sub {
#pod             # ...DBIC calls within transaction...
#pod         },
#pod         @misc_args_passed_to_coderef,
#pod     );
#pod
#pod Works just like L<DBIx::Class::Storage/txn_do>, except it's now protected against
#pod retryable failures.
#pod
#pod Calling this method through the C<$schema> object is typically more convenient.
#pod
#pod =cut

sub txn_do {
    my $self = shift;
    return $self->next::method(@_) unless $self->enable_retryable;

    # Connects or reconnects on pid change to grab correct txn_depth (same as
    # DBIx::Class::Storage::DBI)
    $self->_get_dbh;

    $self->_blockrunner_do( txn_do => @_ );
}

#pod =head2 throw_exception
#pod
#pod     $storage->throw_exception('It failed');
#pod
#pod Works just like L<DBIx::Class::Storage/throw_exception>, but also reports attempt and
#pod timer statistics, in case the transaction was tried multiple times.
#pod
#pod =cut

sub _reset_timers_and_timeouts {
    my $self = shift;

    # Only reset timeouts if we have to, but check before we clear
    my $needs_resetting = $self->_failed_attempt_count && $self->_retryable_current_timeout;

    $self->_retryable_timer(undef);
    $self->_reset_retryable_timeout;

    if ($needs_resetting) {
        $self->_set_dbi_connect_info;
        $self->_set_retryable_session_timeouts;
    }

    # Useful for chaining to the return call in _blockrunner_retry_handler
    return undef;
}

sub _warn_retryable_error {
    my ($self, $error) = @_;

    my $timer = $self->_retryable_timer;
    my $current_attempt_count = $self->_failed_attempt_count + 1;
    my $debug_msg = sprintf(
        'Retrying %s coderef, attempt %u of %u, timer: %.1f / %.1f sec, last exception: %s',
        $self->_retryable_call_type,
        $current_attempt_count, $self->max_attempts,
        $timer->{_last_timestamp} - $timer->{_start_timestamp}, $timer->{max_actual_duration},
        $error
    );

    warn $debug_msg;
}

sub _reset_and_fail {
    my ($self, $fail_reason) = @_;

    # First error: just pass the exception unaltered
    if ($self->_failed_attempt_count <= 1) {
        $self->_retryable_exception_prefix(undef);
        return $self->_reset_timers_and_timeouts;
    }

    my $timer = $self->_retryable_timer;
    $self->_retryable_exception_prefix( sprintf(
        'Failed %s coderef: %s, attempts: %u / %u, timer: %.1f / %.1f sec',
        $self->_retryable_call_type, $fail_reason,
        $self->_failed_attempt_count, $self->max_attempts,
        $timer->{_last_timestamp} - $timer->{_start_timestamp}, $timer->{max_actual_duration},
    ) );

    return $self->_reset_timers_and_timeouts;
}

sub throw_exception {
    my $self = shift;

    # Clear the prefix as we use it
    my $exception_prefix = $self->_retryable_exception_prefix;
    $self->_retryable_exception_prefix(undef) if $exception_prefix;

    return $self->next::method(@_) unless $exception_prefix;

    my $error = shift;
    $exception_prefix .= ', last exception: ';
    if (blessed $error && $error->isa('DBIx::Class::Exception')) {
        $error->{msg} = $exception_prefix.$error->{msg};
    }
    else {
        $error = $exception_prefix.$error;
    }
    return $self->next::method($error, @_);
}

#pod =head1 CAVEATS
#pod
#pod =head2 Transactions without txn_do
#pod
#pod Retryable is transaction-safe.  Only the outermost transaction depth gets the retry
#pod protection, since that's the only layer that is idempotent and atomic.
#pod
#pod However, transaction commands like C<txn_begin> and C<txn_scope_guard> are NOT granted
#pod retry protection, because DBIC/Retryable does not have a defined transaction-safe code
#pod closure to use upon reconnection.  Only C<txn_do> will have the protections available.
#pod
#pod For example:
#pod
#pod     # Has retry protetion
#pod     my $rs = $schema->resultset('Foo');
#pod     $rs->delete;
#pod
#pod     # This effectively turns off retry protection
#pod     $schema->txn_begin;
#pod
#pod     # NOT protected from retryable errors!
#pod     my $result = $rs->create({bar => 12});
#pod     $result->update({baz => 42});
#pod
#pod     $schema->txn_commit;
#pod     # Retry protection is back on
#pod
#pod     # Do this instead!
#pod     $schema->txn_do(sub {
#pod         my $result = $rs->create({bar => 12});
#pod         $result->update({baz => 42});
#pod     });
#pod
#pod     # Still has retry protection
#pod     $rs->delete;
#pod
#pod All of this behavior mimics how DBIC's original storage engines work.
#pod
#pod =head2 (Ab)using $dbh directly
#pod
#pod Similar to C<txn_begin>, directly accessing and using a DBI database or statement handle
#pod does NOT grant retry protection, even if they are acquired from the storage engine via
#pod C<< $storage->dbh >>.
#pod
#pod Instead, use L</dbh_do>.  This method is also used by DBIC for most of its active DB
#pod calls, after it has composed a proper SQL statement to run.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<DBIx::Connector::Retry::MySQL> - A similar engine for DBI connections, using L<DBIx::Connector::Retry> as a base.
#pod
#pod L<DBIx::Class::Storage::BlockRunner> - Base module in DBIC that controls how transactional coderefs are ran and retried
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Storage::DBI::mysql::Retryable - MySQL-specific DBIC storage engine with retry support

=head1 VERSION

version v1.0.0

=head1 SYNOPSIS

    package MySchema;

    # Recommended
    DBIx::Class::Storage::DBI::mysql::Retryable->_use_join_optimizer(0);

    __PACKAGE__->storage_type('::DBI::mysql::Retryable');

    # Optional settings (defaults shown)
    my $storage_class = 'DBIx::Class::Storage::DBI::mysql::Retryable';
    $storage_class->parse_error_class('DBIx::ParseError::MySQL');
    $storage_class->timer_class('Algorithm::Backoff::RetryTimeouts');
    $storage_class->timer_options({});           # same defaults as the timer class
    $storage_class->aggressive_timeouts(0);
    $storage_class->warn_on_retryable_error(0);
    $storage_class->enable_retryable(1);

=head1 DESCRIPTION

This storage engine for L<DBIx::Class> is a MySQL-specific engine that will explicitly
retry on MySQL-specific transient error messages, as identified by L<DBIx::ParseError::MySQL>,
using L<Algorithm::Backoff::RetryTimeouts> as its retry algorithm.  This engine should be
much better at handling deadlocks, connection errors, and Galera node flips to ensure the
transaction always goes through.

=head2 How Retryable Works

A DBIC command triggers some sort of connection to the MySQL server to send SQL.  First,
Retryable makes sure the connection C<mysql_*_timeout> values (except C<mysql_read_timeout>
unless L</aggressive_timeouts> is set) are set properly.  (The default settings for
L<RetryTimeouts|Algorithm::Backoff::RetryTimeouts/Typical scenario> will use half of the
maximum duration, with some jitter.)  If the connection was successful, a few C<SET SESSION>
commands for timeouts are sent first:

    wait_timeout   # only with aggressive_timeouts=1
    lock_wait_timeout
    innodb_lock_wait_timeout
    net_read_timeout
    net_write_timeout

If the DBIC command fails at any point in the process, and the error is a recoverable
failure (according to the L<error parsing class|DBIx::ParseError::MySQL>), the retry
process starts.

The timeouts are only checked during the retry handler.  Since DB operations are XS
calls, Perl-style "safe" ALRM signals won't do any good, and the engine won't attempt to
use unsafe ones.  Thus, the engine relies on the server to honor the timeouts set during
each attempt, and will give up if it runs out of time or attempts.

If the DBIC command succeeds during the process, program flow resumes as normal.  If any
re-attempts happened during the DBIC command, the timeouts are reset back to the original
post-connection values.

=head1 STORAGE OPTIONS

=head2 parse_error_class

Class used to parse MySQL error messages.

Default is L<DBIx::ParseError::MySQL>.  If a different class is used, it must support a
similar interface, especially the L<C<is_transient>|DBIx::ParseError::MySQL/is_transient>
method.

=head2 timer_class

Algorithm class used to determine timeout and sleep values during the retry process.

Default is L<Algorithm::Backoff::RetryTimeouts>.  If a different class is used, it must
support a similar interface, including the dual return of the L<C<failure>|Algorithm::Backoff::RetryTimeouts/failure>
method.

=head2 timer_options

Options to pass to the timer algorithm constructor, as a hashref.

Default is an empty hashref, which would retain all of the defaults of the algorithm
module.

=head2 aggressive_timeouts

Boolean that controls whether to use some of the more aggressive, query-unfriendly
timeouts:

=over

=item mysql_read_timeout

Controls the timeout for all read operations.  Since SQL queries in the middle of
sending its first set of row data are still considered to be in a read operation, those
queries could time out during those circumstances.

If you're confident that you don't have any SQL statements that would take longer than
C<R/2> (or at least returning results before that time), you can turn this option on.
Otherwise, you may experience longer-running statements going into a retry death spiral
until they finally hit the Retryable timeout for good and die.

=item wait_timeout

Controls how long the MySQL server waits for activity from the connection before timing
out.  While most applications are going to be using the database connection pretty
frequently, the MySQL default (8 hours) is much much longer than the mere seconds this
engine would set it to.

=back

Default is off.  Obviously, this setting only makes sense with L</retryable_timeout>
turned on.

=head2 warn_on_retryable_error

Boolean that controls whether to warn on retryable failures, as the engine encounters
them.  Many applications don't want spam on their screen for recoverable conditions, but
this may be useful for debugging or CLI tools.

Unretryable failures always generate an exception as normal, regardless of the setting.

This is functionally equivalent to L<DBI/PrintError>, but since L<"RaiseError"|DBI/RaiseError>
is already the DBIC-required default, the former option can't be used within DBI.

Default is off.

=head2 enable_retryable

Boolean that enables the Retryable logic.  This can be turned off to temporarily disable
it, and revert to DBIC's basic "retry once if disconnected" default.  This may be useful
if a process is already using some other retry logic (like L<DBIx::OnlineDDL>).

Messing with this setting in the middle of a database action would not be wise.

Default is on.

=head1 METHODS

=head2 dbh_do

    my $val = $schema->storage->dbh_do(
        sub {
            my ($storage, $dbh, @binds) = @_;
            $dbh->selectrow_array($sql, undef, @binds);
        },
        @passed_binds,
    );

This is very much like L<DBIx::Class::Storage::DBI/dbh_do>, except it doesn't require a
connection failure to retry the sub block.  Instead, it will also retry on locks, query
interruptions, and failovers.

Normal users of DBIC typically won't use this method directly.  Instead, any ResultSet
or Result method that contacts the DB will send its SQL through here, and protect it from
retryable failures.

However, this method is recommended over using C<< $schema->storage->dbh >> directly to
run raw SQL statements.

=head2 txn_do

    my $val = $schema->txn_do(
        sub {
            # ...DBIC calls within transaction...
        },
        @misc_args_passed_to_coderef,
    );

Works just like L<DBIx::Class::Storage/txn_do>, except it's now protected against
retryable failures.

Calling this method through the C<$schema> object is typically more convenient.

=head2 throw_exception

    $storage->throw_exception('It failed');

Works just like L<DBIx::Class::Storage/throw_exception>, but also reports attempt and
timer statistics, in case the transaction was tried multiple times.

=head1 CAVEATS

=head2 Transactions without txn_do

Retryable is transaction-safe.  Only the outermost transaction depth gets the retry
protection, since that's the only layer that is idempotent and atomic.

However, transaction commands like C<txn_begin> and C<txn_scope_guard> are NOT granted
retry protection, because DBIC/Retryable does not have a defined transaction-safe code
closure to use upon reconnection.  Only C<txn_do> will have the protections available.

For example:

    # Has retry protetion
    my $rs = $schema->resultset('Foo');
    $rs->delete;

    # This effectively turns off retry protection
    $schema->txn_begin;

    # NOT protected from retryable errors!
    my $result = $rs->create({bar => 12});
    $result->update({baz => 42});

    $schema->txn_commit;
    # Retry protection is back on

    # Do this instead!
    $schema->txn_do(sub {
        my $result = $rs->create({bar => 12});
        $result->update({baz => 42});
    });

    # Still has retry protection
    $rs->delete;

All of this behavior mimics how DBIC's original storage engines work.

=head2 (Ab)using $dbh directly

Similar to C<txn_begin>, directly accessing and using a DBI database or statement handle
does NOT grant retry protection, even if they are acquired from the storage engine via
C<< $storage->dbh >>.

Instead, use L</dbh_do>.  This method is also used by DBIC for most of its active DB
calls, after it has composed a proper SQL statement to run.

=head1 SEE ALSO

L<DBIx::Connector::Retry::MySQL> - A similar engine for DBI connections, using L<DBIx::Connector::Retry> as a base.

L<DBIx::Class::Storage::BlockRunner> - Base module in DBIC that controls how transactional coderefs are ran and retried

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
