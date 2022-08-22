package DBIx::Connector::Retry::MySQL;

# ABSTRACT: MySQL-specific DBIx::Connector with retry support
use version;
our $VERSION = 'v1.0.1'; # VERSION

use strict;
use warnings;

use Moo;

extends 'DBIx::Connector::Retry';

use Scalar::Util           qw( weaken );
use Storable               qw( dclone );
use Types::Standard        qw( Bool HashRef InstanceOf ClassName );
use Types::Common::Numeric qw( PositiveOrZeroNum PositiveOrZeroInt );
use Time::HiRes            qw( sleep );

use Algorithm::Backoff::RetryTimeouts;
use DBIx::ParseError::MySQL;

use namespace::clean;  # don't export the above

#pod =head1 SYNOPSIS
#pod
#pod     my $conn = DBIx::Connector::Retry::MySQL->new(
#pod         connect_info  => [ 'dbi:Driver:database=foobar', $user, $pass, \%args ],
#pod         retry_debug   => 1,
#pod         timer_options => {
#pod             # Default options from Algorithm::Backoff::RetryTimeouts
#pod             max_attempts          => 8,
#pod             max_actual_duration   => 50,
#pod             jitter_factor         => 0.1,
#pod             timeout_jitter_factor => 0.1,
#pod             adjust_timeout_factor => 0.5,
#pod             min_adjust_timeout    => 5,
#pod             # ...among others
#pod         },
#pod     );
#pod
#pod     # Keep retrying/reconnecting on errors
#pod     my ($count) = $conn->run(ping => sub {
#pod         $_->do('UPDATE foobar SET updated = 1 WHERE active = ?', undef, 'on');
#pod         $_->selectrow_array('SELECT COUNT(*) FROM foobar WHERE updated = 1');
#pod     });
#pod
#pod     my ($count) = $conn->txn(fixup => sub {
#pod         $_->selectrow_array('SELECT COUNT(*) FROM barbaz');
#pod     });
#pod
#pod     # Plus everything else in DBIx::Connector::Retry and DBIx::Connector
#pod
#pod =head1 DESCRIPTION
#pod
#pod DBIx::Connector::Retry::MySQL is a subclass of L<DBIx::Connector::Retry> that will
#pod explicitly retry on MySQL-specific transient error messages, as identified by
#pod L<DBIx::ParseError::MySQL>, using L<Algorithm::Backoff::RetryTimeouts> as its retry
#pod algorithm.  This connector should be much better at handling deadlocks, connection
#pod errors, and Galera node flips to ensure the transaction always goes through.
#pod
#pod It is essentially a DBIx::Connector version of L<DBIx::Class::Storage::DBI::mysql::Retryable>.
#pod
#pod =head1 INHERITED ATTRIBUTES
#pod
#pod This inherits all of the attributes of L<DBIx::Connector::Retry>:
#pod
#pod =head2 L<connect_info|DBIx::Connector::Retry/connect_info>
#pod
#pod =head2 L<mode|DBIx::Connector::Retry/mode>
#pod
#pod =head2 L<disconnect_on_destroy|DBIx::Connector::Retry/disconnect_on_destroy>
#pod
#pod =head2 max_attempts
#pod
#pod Unlike L<DBIx::Connector::Retry/max_attempts>, this is just an alias to the value in
#pod L</timer_options>.
#pod
#pod As such, it has a slightly adjusted default of 8.
#pod
#pod =cut

sub max_attempts {
    my $self = shift;
    my $opts = $self->timer_options;

    return $opts->{max_attempts} = $_[0] if @_;
    return $opts->{max_attempts} // 8;
}

#pod =head2 retry_debug
#pod
#pod Like L<retry_debug|DBIx::Connector::Retry/retry_debug>, this turns on debug warnings for
#pod retries.  But, this module has a bit more detail in the messages.
#pod
#pod =cut

sub _warn_retry_debug {
    my $self = shift;

    my $timer = $self->_timer;
    my $current_attempt_count = $self->failed_attempt_count + 1;
    my $debug_msg = sprintf(
        'Retrying %s coderef, attempt %u of %u, timer: %.1f / %.1f sec, last exception: %s',
        $self->execute_method,
        $current_attempt_count, $self->max_attempts,
        $timer->{_last_timestamp} - $timer->{_start_timestamp}, $timer->{max_actual_duration},
        $self->last_exception
    );

    warn $debug_msg;
}

#pod =head2 retry_handler
#pod
#pod Since the whole point of the module is the retry-handling code, this attribute cannot be
#pod set.
#pod
#pod =cut

sub retry_handler { \&_main_retry_handler };

#pod =head2 failed_attempt_count
#pod
#pod Unlike L<DBIx::Connector::Retry/failed_attempt_count>, this is just an alias to the
#pod value in the internal timer object.
#pod
#pod =cut

sub failed_attempt_count { shift->_timer->{_attempts} // 0 }

# This neuters the max_attempts trigger in failed_attempt_count, so that the main check
# in _main_retry_handler works as expected.
sub _set_failed_attempt_count {}

#pod =head2 L<exception_stack|DBIx::Connector::Retry/exception_stack>
#pod
#pod =head1 NEW ATTRIBUTES
#pod
#pod =head2 timer_class
#pod
#pod The class used for delay and timeout setting calculations.  By default, it's
#pod L<Algorithm::Backoff::RetryTimeouts>, but you can use a sub-class of this, if you so
#pod choose, provided that it has a similar interface.
#pod
#pod =cut

has timer_class => (
    is       => 'ro',
    isa      => ClassName,
    default  => 'Algorithm::Backoff::RetryTimeouts',
);

#pod =head2 timer_options
#pod
#pod Controls all of the options passed to the timer constructor, using L</timer_class> as the
#pod object.
#pod
#pod =cut

has timer_options => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
    lazy     => 1,
);

has _timer => (
    is       => 'rw',
    isa      => InstanceOf['Algorithm::Backoff::RetryTimeouts'],
    init_arg => undef,
    builder  => '_build_timer',
    clearer  => '_clear_timer',
    lazy     => 1,
);

sub _build_timer {
    my $self = shift;
    return $self->timer_class->new(
        %{ dclone $self->timer_options }
    );
}

has _current_timeout => (
    is       => 'rw',
    isa      => PositiveOrZeroNum,
    init_arg => undef,
    lazy     => 1,
);

sub _reset_timeout {
    my $self = shift;

    # Use a temporary timer to get the first timeout value
    my $timeout = $self->_build_timer->timeout;
    $timeout = 0 if $timeout == -1;
    $self->_current_timeout($timeout);
}

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
#pod the timeout settings (or at least returning results before that time), you can turn this
#pod option on.  Otherwise, you may experience longer-running statements going into a retry
#pod death spiral until they hit the final timeout and die.
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
#pod Default is off.  Obviously, this setting makes no sense if C<max_actual_duration>
#pod within L</timeout_options> is disabled.
#pod
#pod =cut

has aggressive_timeouts => (
    is       => 'rw',
    isa      => Bool,
    required => 0,
    default  => 0,
);

#pod =head2 retries_before_error_prefix
#pod
#pod Controls the number of retries (not tries) needed before the exception message starts
#pod using the statistics prefix, which looks something like this:
#pod
#pod     Failed run coderef: Out of retries, attempts: 5 / 4, timer: 34.5 / 50.0 sec
#pod
#pod The default is 1, which means a failed first attempt (like a non-transient failure) will
#pod show a normal exception, and the second attempt will use the prefix.  You can set this to
#pod 0 to always show the prefix, or a large number like 99 to keep the exception clean.
#pod
#pod =cut

has retries_before_error_prefix => (
    is       => 'rw',
    isa      => PositiveOrZeroInt,
    required => 0,
    default  => 1,
);

#pod =head2 parse_error_class
#pod
#pod The class used for MySQL error parsing.  By default, it's L<DBIx::ParseError::MySQL>, but
#pod you can use a sub-class of this, if you so choose, provided that it has a similar
#pod interface.
#pod
#pod =cut

has parse_error_class => (
    is       => 'ro',
    isa      => ClassName,
    default  => 'DBIx::ParseError::MySQL',
);

#pod =head2 enable_retry_handler
#pod
#pod Boolean to enable the retry handler.  The default is, of course, on.  This can be turned
#pod off to temporarily disable the retry handler.
#pod
#pod =cut

has enable_retry_handler => (
    is       => 'rw',
    isa      => Bool,
    required => 0,
    default  => 1,
);

# Alias for backwards-compatibility
sub clear_retry_handler { shift->enable_retry_handler(0) }

### All the lifecycle and private methods

# Force in our retry_handler
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    my $args = $class->$orig(@args);
    $args->{retry_handler} = \&_main_retry_handler;

    return $args;
};

sub BUILD {
    my $self = shift;
    $self->_reset_timeout;
    $self->_set_dbi_connect_info;
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
sub _set_dbi_connect_info {
    my $self = shift;
    return unless $self->_current_timeout && $self->enable_retry_handler;

    my $timeout  = int( $self->_current_timeout + 0.5 );
    my $dbi_attr = $self->connect_info->[3] //= {};
    return unless $dbi_attr && ref $dbi_attr eq 'HASH';

    $dbi_attr->{mysql_auto_reconnect} = 0;  # do not use MySQL's own reconnector
    $dbi_attr->{$_} = $timeout for $self->_timeout_set_list('dbi');
}

# Set session timeouts for post-connection variables
after _connect => sub {
    my $self = shift;
    $self->_set_retry_session_timeouts;
};

sub _set_retry_session_timeouts {
    my $self = shift;
    return unless $self->_current_timeout && $self->enable_retry_handler;

    my $timeout = int( $self->_current_timeout + 0.5 );

    # Ironically, we aren't running our own SET SESSION commands with their own
    # retry protection, since that may lead to infinite stack recursion.  Instead,
    # put it in a basic eval, and do a quick is_transient check.  If it passes,
    # let the next _run/_retry_loop call handle it.

    local $@;
    eval {
        # Don't let outside handlers ruin our error checking.  This expires before our
        # 'die' statement below.
        local $SIG{__DIE__};

        my $dbh = $self->{_dbh};
        if ($dbh) {
            $dbh->do("SET SESSION $_=$timeout") for $self->_timeout_set_list('session');
        }
    };
    if (my $error = $@) {
        my $parsed_error = $self->parse_error_class->new($error);
        die unless $parsed_error->is_transient;  # bare die for $@ propagation
        warn "Encountered a recoverable error during SET SESSION timeout commands: $error" if $self->retry_debug;
    }
}

# Override fixup methods (pretend we're using no_ping mode with our own retry protections)
sub _fixup_run {
    my ($self, $code) = @_;
    return $self->_run($code);
}

sub _txn_fixup_run {
    my ($self, $code) = @_;
    return $self->_txn_run($code);
}

# Modifications of the main retry loop
around _retry_loop => sub {
    my $orig = shift;
    my $self = shift;
    my $wantarray = $_[4];  # keep it in the parameter list

    # Start new timer
    $self->_clear_timer;

    my $timeout = $self->_timer->timeout;
    $timeout = 0 if $timeout == -1;
    $self->_current_timeout($timeout);

    # Save the result in a context-sensitive manner, but reset timers before we return
    my @res;
    unless (defined $wantarray) {           $self->$orig(@_) }
    elsif          ($wantarray) { @res    = $self->$orig(@_) }
    else                        { $res[0] = $self->$orig(@_) }

    $self->_reset_timers_and_timeouts;
    return $wantarray ? @res : $res[0];
};

# Our retry handler
sub _main_retry_handler {
    my $self = shift;

    my $last_error = $self->last_exception;

    # Record the failure in the timer algorithm (prior to any checks)
    my ($sleep_time, $new_timeout) = $self->_timer->failure;

    # Retry handler is disabled?
    $self->_reset_and_die('Retry handler disabled') unless $self->enable_retry_handler;

    # If it's not a retryable error, stop here
    my $parsed_error = $self->parse_error_class->new($last_error);
    $self->_reset_and_die('Exception not transient') unless $parsed_error->is_transient;

    # Either stop here (because of timeout or max attempts), sleep, or don't
    if    ($sleep_time == -1) { $self->_reset_and_die('Out of retries') }
    elsif ($sleep_time)       { sleep $sleep_time;                      }

    if ($new_timeout > 0) {
        # Reset the connection timeouts before we connect again
        $self->_current_timeout($new_timeout);
        $self->_set_dbi_connect_info;
    }

    # Force a disconnect, but only if the connection seems to be in a broken state
    unless ($parsed_error->error_type eq 'lock') {
        local $@;
        eval { local $SIG{__DIE__}; $self->disconnect };
    }

    return 1;
}

sub _reset_timers_and_timeouts {
    my $self = shift;

    # Only reset timeouts if we have to, but check before we clear
    my $needs_resetting = $self->failed_attempt_count && $self->_current_timeout;

    $self->_clear_timer;
    $self->_reset_timeout;

    if ($needs_resetting) {
        $self->_set_dbi_connect_info;
        $self->_set_retry_session_timeouts;
    }

    return undef;
}

sub _reset_and_die {
    my ($self, $fail_reason) = @_;

    # First error (by default): just pass it unaltered
    die $self->last_exception if $self->failed_attempt_count <= $self->retries_before_error_prefix;

    my $timer = $self->_timer;
    my $error = sprintf(
        'Failed %s coderef: %s, attempts: %u / %u, timer: %.1f / %.1f sec, last exception: %s',
        $self->execute_method, $fail_reason,
        $self->failed_attempt_count, $self->max_attempts,
        $timer->{_last_timestamp} - $timer->{_start_timestamp}, $timer->{max_actual_duration},
        $self->last_exception
    );

    $self->_reset_timers_and_timeouts;
    die $error;
}

#pod =head1 CAVEATS
#pod
#pod =head2 $dbh settings
#pod
#pod See L<DBIx::Connector::Retry/$dbh settings>.
#pod
#pod =head2 Savepoints and nested transactions
#pod
#pod See L<DBIx::Connector::Retry/Savepoints and nested transactions>.
#pod
#pod =head2 (Ab)using $dbh directly
#pod
#pod See L<DBIx::Connector::Retry/(Ab)using $dbh directly>.
#pod
#pod =head2 Connection modes
#pod
#pod Due to the caveats of L<DBIx::Connector::Retry/Fixup mode>, C<fixup> mode is changed to
#pod just act like C<no_ping> mode.  However, C<no_ping> mode is safer to use in this module
#pod because it comes with the same retry protections as the other modes.  Certain retries,
#pod such as connection/server errors, come with an explicit disconnect to make sure it starts
#pod back up with a clean slate.
#pod
#pod In C<ping> mode, the DB will be pinged on the first try.  If the retry explicitly
#pod disconnected, the connector will simply connect back to the DB and run the code, without
#pod a superfluous ping.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Connector::Retry::MySQL - MySQL-specific DBIx::Connector with retry support

=head1 VERSION

version v1.0.1

=head1 SYNOPSIS

    my $conn = DBIx::Connector::Retry::MySQL->new(
        connect_info  => [ 'dbi:Driver:database=foobar', $user, $pass, \%args ],
        retry_debug   => 1,
        timer_options => {
            # Default options from Algorithm::Backoff::RetryTimeouts
            max_attempts          => 8,
            max_actual_duration   => 50,
            jitter_factor         => 0.1,
            timeout_jitter_factor => 0.1,
            adjust_timeout_factor => 0.5,
            min_adjust_timeout    => 5,
            # ...among others
        },
    );

    # Keep retrying/reconnecting on errors
    my ($count) = $conn->run(ping => sub {
        $_->do('UPDATE foobar SET updated = 1 WHERE active = ?', undef, 'on');
        $_->selectrow_array('SELECT COUNT(*) FROM foobar WHERE updated = 1');
    });

    my ($count) = $conn->txn(fixup => sub {
        $_->selectrow_array('SELECT COUNT(*) FROM barbaz');
    });

    # Plus everything else in DBIx::Connector::Retry and DBIx::Connector

=head1 DESCRIPTION

DBIx::Connector::Retry::MySQL is a subclass of L<DBIx::Connector::Retry> that will
explicitly retry on MySQL-specific transient error messages, as identified by
L<DBIx::ParseError::MySQL>, using L<Algorithm::Backoff::RetryTimeouts> as its retry
algorithm.  This connector should be much better at handling deadlocks, connection
errors, and Galera node flips to ensure the transaction always goes through.

It is essentially a DBIx::Connector version of L<DBIx::Class::Storage::DBI::mysql::Retryable>.

=head1 INHERITED ATTRIBUTES

This inherits all of the attributes of L<DBIx::Connector::Retry>:

=head2 L<connect_info|DBIx::Connector::Retry/connect_info>

=head2 L<mode|DBIx::Connector::Retry/mode>

=head2 L<disconnect_on_destroy|DBIx::Connector::Retry/disconnect_on_destroy>

=head2 max_attempts

Unlike L<DBIx::Connector::Retry/max_attempts>, this is just an alias to the value in
L</timer_options>.

As such, it has a slightly adjusted default of 8.

=head2 retry_debug

Like L<retry_debug|DBIx::Connector::Retry/retry_debug>, this turns on debug warnings for
retries.  But, this module has a bit more detail in the messages.

=head2 retry_handler

Since the whole point of the module is the retry-handling code, this attribute cannot be
set.

=head2 failed_attempt_count

Unlike L<DBIx::Connector::Retry/failed_attempt_count>, this is just an alias to the
value in the internal timer object.

=head2 L<exception_stack|DBIx::Connector::Retry/exception_stack>

=head1 NEW ATTRIBUTES

=head2 timer_class

The class used for delay and timeout setting calculations.  By default, it's
L<Algorithm::Backoff::RetryTimeouts>, but you can use a sub-class of this, if you so
choose, provided that it has a similar interface.

=head2 timer_options

Controls all of the options passed to the timer constructor, using L</timer_class> as the
object.

=head2 aggressive_timeouts

Boolean that controls whether to use some of the more aggressive, query-unfriendly
timeouts:

=over

=item mysql_read_timeout

Controls the timeout for all read operations.  Since SQL queries in the middle of
sending its first set of row data are still considered to be in a read operation, those
queries could time out during those circumstances.

If you're confident that you don't have any SQL statements that would take longer than
the timeout settings (or at least returning results before that time), you can turn this
option on.  Otherwise, you may experience longer-running statements going into a retry
death spiral until they hit the final timeout and die.

=item wait_timeout

Controls how long the MySQL server waits for activity from the connection before timing
out.  While most applications are going to be using the database connection pretty
frequently, the MySQL default (8 hours) is much much longer than the mere seconds this
engine would set it to.

=back

Default is off.  Obviously, this setting makes no sense if C<max_actual_duration>
within L</timeout_options> is disabled.

=head2 retries_before_error_prefix

Controls the number of retries (not tries) needed before the exception message starts
using the statistics prefix, which looks something like this:

    Failed run coderef: Out of retries, attempts: 5 / 4, timer: 34.5 / 50.0 sec

The default is 1, which means a failed first attempt (like a non-transient failure) will
show a normal exception, and the second attempt will use the prefix.  You can set this to
0 to always show the prefix, or a large number like 99 to keep the exception clean.

=head2 parse_error_class

The class used for MySQL error parsing.  By default, it's L<DBIx::ParseError::MySQL>, but
you can use a sub-class of this, if you so choose, provided that it has a similar
interface.

=head2 enable_retry_handler

Boolean to enable the retry handler.  The default is, of course, on.  This can be turned
off to temporarily disable the retry handler.

=head1 CAVEATS

=head2 $dbh settings

See L<DBIx::Connector::Retry/$dbh settings>.

=head2 Savepoints and nested transactions

See L<DBIx::Connector::Retry/Savepoints and nested transactions>.

=head2 (Ab)using $dbh directly

See L<DBIx::Connector::Retry/(Ab)using $dbh directly>.

=head2 Connection modes

Due to the caveats of L<DBIx::Connector::Retry/Fixup mode>, C<fixup> mode is changed to
just act like C<no_ping> mode.  However, C<no_ping> mode is safer to use in this module
because it comes with the same retry protections as the other modes.  Certain retries,
such as connection/server errors, come with an explicit disconnect to make sure it starts
back up with a clean slate.

In C<ping> mode, the DB will be pinged on the first try.  If the retry explicitly
disconnected, the connector will simply connect back to the DB and run the code, without
a superfluous ping.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 - 2022 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
