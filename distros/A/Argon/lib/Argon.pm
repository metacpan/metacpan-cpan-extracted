package Argon;

our $VERSION = '0.16';

use strict;
use warnings;
use Carp;
use Const::Fast;
use Coro;
use Scalar::Util  qw(weaken refaddr);
use POSIX         qw(strftime);
use Log::Log4perl qw();

if ($^O eq 'MSWin32') {
    die 'MSWin32 is not supported';
}

require Exporter;
use base qw/Exporter/;

our %EXPORT_TAGS = (
    # Priorities
    priorities => [qw($PRI_HIGH $PRI_NORMAL $PRI_LOW)],

    # Command verbs and responses
    commands => [qw(
        $CMD_PING $CMD_QUEUE $CMD_COLLECT $CMD_REGISTER $CMD_STATUS
        $CMD_ACK $CMD_COMPLETE $CMD_ERROR $CMD_REJECTED
    )],

    logging => [qw(
        SET_LOG_LEVEL
        $TRACE TRACE
        $DEBUG DEBUG
        $INFO  INFO
        $WARN  WARN
        $ERROR ERROR
        $FATAL FATAL
    )],
);

our @EXPORT_OK = ('K', map { @$_ } values %EXPORT_TAGS);

#-------------------------------------------------------------------------------
# Returns a new function suitable for use as a callback. This is useful to pass
# instance methods as callbacks without leaking references.
#
# Inputs:
#     $fn      : CODE reference or function name
#     $context : class name or object instance
#     @args    : other arguments to pass to $fn
#
# Output:
#     CODE reference
#
# Examples:
#     # Using a function reference
#     my $cb = K(\&on_connection);
#
#     # Using an instance method
#     my $cb = K('on_connection', $client);
#
#     # Using a class method
#     my $cb = K('on_connection', 'ClientClass');
#
#     # With extra arguments
#     my $cb = K('on_connection', $client, 'x', 'y', 'z');
#-------------------------------------------------------------------------------
sub K {
    my ($fn, $context, @args) = @_;

    croak "unknown method $fn"
        if !ref $context
        || !$context->can($fn);

    weaken $context;
    my $k = $context->can($fn);

    return sub {
        unshift @_, $context, @args;
        goto $k;
    };
}

#-------------------------------------------------------------------------------
# Defaults
#-------------------------------------------------------------------------------
our $EOL                = "\n";    # end of line/message character(s)
our $MSG_SEPARATOR      = ' ';     # separator between parts of a message (command, priority, payload, etc)
our $TRACK_MESSAGES     = 10;      # number of message times to track for computing avg processing time at a host
our $POLL_INTERVAL      = 5;       # number of seconds between polls for connectivity between cluster/node
our $CONNECT_TIMEOUT    = 5;       # number of seconds after which a stream times out attempting to connect
our $DEL_COMPLETE_AFTER = 30 * 60; # number of seconds after which a completed task's result is delete if not collected

#-------------------------------------------------------------------------------
# Priorities
#-------------------------------------------------------------------------------
const our $PRI_HIGH   => Coro::PRIO_HIGH;
const our $PRI_NORMAL => Coro::PRIO_NORMAL;
const our $PRI_LOW    => Coro::PRIO_MIN;

#-------------------------------------------------------------------------------
# Commands
#-------------------------------------------------------------------------------
const our $CMD_PING     => 0; # Verify that a worker is responding
const our $CMD_QUEUE    => 1; # Queue a message
const our $CMD_COLLECT  => 2; # Collect results
const our $CMD_REGISTER => 3; # Add a node to a cluster
const our $CMD_STATUS   => 4; # Get process and system status from a manager

const our $CMD_ACK      => 5; # Acknowledgement (respond OK)
const our $CMD_COMPLETE => 6; # Response - message is complete
const our $CMD_ERROR    => 7; # Response - error processing message or invalid message format
const our $CMD_REJECTED => 8; # Response - no available capacity for handling tasks

#-------------------------------------------------------------------------------
# Logging
#-------------------------------------------------------------------------------
const our $TRACE => $Log::Log4perl::TRACE;
const our $DEBUG => $Log::Log4perl::DEBUG;
const our $INFO  => $Log::Log4perl::INFO;
const our $WARN  => $Log::Log4perl::WARN;
const our $ERROR => $Log::Log4perl::ERROR;
const our $FATAL => $Log::Log4perl::FATAL;

my $LOGGER = Log::Log4perl->get_logger('argon');

sub SET_LOG_LEVEL {
    Log::Log4perl->easy_init($_[0]);
}

# Strips an error message of line number and file information.
sub error {
    my $msg = shift;
    $msg =~ s/ at (.+?) line \d+.//gsm;
    $msg =~ s/eval {...} called$//gsm;
    $msg =~ s/\s+$//gsm;
    $msg =~ s/^\s+//gsm;
    return $msg;
}

sub LOG {
    my $lvl  = lc shift;
    my $coro = $Coro::current + 0;
    my $msg  = sprintf('[%s] [%s] => %s', $$, $coro, error(sprintf(shift, @_)));
    $LOGGER->$lvl($msg);
}

sub TRACE { LOG(trace => @_) }
sub DEBUG { LOG(debug => @_) }
sub INFO  { LOG(info  => @_) }
sub WARN  { LOG(warn  => @_) }
sub ERROR { LOG(error => @_) }
sub FATAL { LOG(fatal => @_) }

SET_LOG_LEVEL $ERROR
    unless Log::Log4perl->initialized;

1;
