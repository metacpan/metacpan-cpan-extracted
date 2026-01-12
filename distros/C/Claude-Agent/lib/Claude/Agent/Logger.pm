package Claude::Agent::Logger;

use 5.020;
use strict;
use warnings;

use Log::Any ();

=head1 NAME

Claude::Agent::Logger - Configurable logging for Claude Agent SDK

=head1 SYNOPSIS

    # In your application - configure logging via environment:
    # CLAUDE_AGENT_DEBUG=1 perl myapp.pl           # debug level to stderr
    # CLAUDE_AGENT_LOG_LEVEL=trace perl myapp.pl   # trace level to stderr
    # CLAUDE_AGENT_LOG_OUTPUT=/tmp/app.log perl myapp.pl  # log to file

    # Or configure your own adapter (takes precedence):
    use Log::Any::Adapter ('Screen', colored => 1);
    use Claude::Agent qw(query);

    # In library code (single import does both setup and $log export):
    use Claude::Agent::Logger '$log';
    $log->debug("Starting query");
    $log->trace("Verbose details: %s", $data);

=head1 DESCRIPTION

This module configures Log::Any with sensible defaults for the Claude Agent SDK.
It provides:

=over 4

=item * Default adapter (Stderr) so logs aren't lost

=item * Environment variable configuration

=item * Backward compatibility with CLAUDE_AGENT_DEBUG

=item * User can override with their own Log::Any::Adapter

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item CLAUDE_AGENT_LOG_LEVEL

Set the minimum log level. Values: trace, debug, info, notice, warning, error, critical, alert, emergency.
Default: warning

=item CLAUDE_AGENT_LOG_OUTPUT

Set the output destination. Values: stderr, stdout, or a file path.
Default: stderr

=item CLAUDE_AGENT_DEBUG

Backward compatibility. Set to 1 for debug level, 2 for trace level.
CLAUDE_AGENT_LOG_LEVEL takes precedence if both are set.

=back

=head1 USER CONFIGURATION

Users can configure their own Log::Any adapter which takes precedence over
environment variables:

    use Log::Any::Adapter ('Screen', colored => 1);
    use Log::Any::Adapter ('File', '/var/log/myapp.log');
    use Log::Any::Adapter ('Log4perl');

=cut

my $_adapter_configured = 0;

sub import {
    my ($class, @args) = @_;
    my $caller = caller;

    # Configure adapter once
    unless ($_adapter_configured) {
        $_adapter_configured = 1;
        _setup_default_adapter();
    }

    # Export $log to caller if requested
    for my $arg (@args) {
        if ($arg eq '$log') {
            my $logger = Log::Any->get_logger(category => $caller);
            no strict 'refs';  ## no critic (ProhibitNoStrict)
            *{"${caller}::log"} = \$logger;
        }
    }

    return;
}

sub _setup_default_adapter {
    # Check for our env vars to configure default logging
    my $level  = $ENV{CLAUDE_AGENT_LOG_LEVEL};
    my $output = $ENV{CLAUDE_AGENT_LOG_OUTPUT};
    my $debug  = $ENV{CLAUDE_AGENT_DEBUG};

    # Determine effective level
    # Default: warning (not silent, not noisy)
    my $effective_level = 'warning';
    if ($level) {
        $effective_level = $level;
    }
    elsif (defined $debug && $debug) {
        $effective_level = $debug > 1 ? 'trace' : 'debug';
    }

    # Configure adapter based on output destination
    require Log::Any::Adapter;

    if ($output && $output ne 'stderr') {
        if ($output eq 'stdout') {
            Log::Any::Adapter->set(
                { formatter => \&_format_message },
                'Stdout',
                log_level => $effective_level,
            );
        }
        else {
            # File path
            Log::Any::Adapter->set(
                { formatter => \&_format_message },
                'File',
                $output,
                log_level => $effective_level,
            );
        }
    }
    else {
        # Default: stderr
        Log::Any::Adapter->set(
            { formatter => \&_format_message },
            'Stderr',
            log_level => $effective_level,
        );
    }

    return;
}

# Format message with sprintf-style placeholders
sub _format_message {
    my ($category, $level, $message, @args) = @_;
    # Apply sprintf if there are format arguments
    if (@args) {
        $message = sprintf($message, @args);
    }
    return $message;
}

=head1 FUNCTIONS

=head2 get_logger

    my $log = Claude::Agent::Logger::get_logger();
    my $log = Claude::Agent::Logger::get_logger('My::Category');

Returns a Log::Any logger instance. Optionally pass a category name.

=cut

sub get_logger {
    my ($category) = @_;
    $category //= scalar caller;
    return Log::Any->get_logger(category => $category);
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
