package Claude::Agent::MCP::SDKRunner;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Logger '$log';
use IO::Socket::UNIX;
use IO::Async::Loop;
use IO::Async::Stream;
use JSON::Lines;
use Try::Tiny;

=head1 NAME

Claude::Agent::MCP::SDKRunner - MCP server runner for SDK tools

=head1 DESCRIPTION

This module implements the MCP server protocol and forwards tool calls
to the parent Perl process via a Unix socket. It is spawned as a child
process by the Claude CLI.

=head1 SYNOPSIS

    # Called internally by the SDK - not for direct use
    perl -MClaude::Agent::MCP::SDKRunner -e 'Claude::Agent::MCP::SDKRunner::run()' \
        -- /path/to/socket server_name 1.0.0 '[{"name":"tool1",...}]'

=cut

# Module-level state - encapsulated in a state object for cleaner isolation
# All state is reset atomically at the start of run() to handle persistent interpreters
sub _make_state_class {
    my $class = 'Claude::Agent::MCP::SDKRunner::State';
    no strict 'refs';  ## no critic (ProhibitNoStrict)
    *{"${class}::new"} = sub {
        my ($cls) = @_;
        return bless {
            socket          => undef,
            socket_stream   => undef,
            request_id      => 0,
            pending_requests => {},
            pending_responses => {},  # Initialize alongside other state variables
            jsonl           => undef,
            loop            => undef,
            response_buffer => '',
            got_response    => 0,
        }, $cls;
    };
    *{"${class}::reset_state"} = sub {
        my ($self) = @_;
        $self->{socket} = undef;
        $self->{socket_stream} = undef;
        $self->{request_id} = 0;
        $self->{pending_requests} = {};
        $self->{pending_responses} = {};  # Initialize alongside other state variables
        $self->{jsonl} = JSON::Lines->new;
        $self->{loop} = undef;
        $self->{response_buffer} = '';
        $self->{got_response} = 0;
        return $self;
    };
    return $class;
}
BEGIN { _make_state_class() }

# Single state object - reset atomically at start of run()
my $state = Claude::Agent::MCP::SDKRunner::State->new;

# Accessors for backward compatibility with existing code
sub _socket        { return $state->{socket}; }
sub _socket_stream { return $state->{socket_stream}; }
sub _request_id    { return $state->{request_id}; }
sub _jsonl         { return $state->{jsonl}; }
sub _loop          { return $state->{loop}; }
sub _response_buffer { return $state->{response_buffer}; }
sub _got_response  { return $state->{got_response}; }

sub run {
    # Reset all state atomically - no gap between declaration and initialization
    $state->reset_state();

    binmode(STDIN,  ':raw');
    binmode(STDOUT, ':raw');
    binmode(STDERR, ':encoding(UTF-8)');

    # Parse arguments
    my ($socket_path, $server_name, $version, $tools_json) = @ARGV;

    unless ($socket_path && $server_name && $tools_json) {
        die "Usage: SDKRunner <socket_path> <server_name> <version> <tools_json>\n";
    }

    # Validate socket path - must be absolute and within a known temp directory
    # This prevents attackers from pointing to attacker-controlled sockets outside
    # the expected secure locations.
    die "Invalid socket path: must be absolute\n" unless $socket_path =~ m{^/};

    # Validate socket is in a known temporary directory pattern
    # Security: Accept common temp directory patterns and user home directories
    # where File::Temp would create sockets
    my $valid_socket_path = 0;
    my @allowed_prefixes = (
        '/tmp/',
        '/var/tmp/',
        '/private/tmp/',          # macOS
        '/var/folders/',          # macOS sandbox temp
        '/run/user/',             # systemd user runtime
    );
    # Also allow user home directory temp locations
    if ($ENV{HOME} && $ENV{HOME} =~ m{^/}) {
        push @allowed_prefixes, "$ENV{HOME}/tmp/";
        push @allowed_prefixes, "$ENV{HOME}/.tmp/";
    }
    # Allow TMPDIR if set (File::Temp respects this)
    # *** SECURITY WARNING ***
    # TMPDIR is user-controllable and NOT validated for trust.
    # KNOWN RISK: An attacker who can set TMPDIR before process startup
    # could influence which socket paths are allowed, potentially enabling
    # connections to attacker-controlled sockets.
    #
    # FOR HIGH-SECURITY DEPLOYMENTS: Set CLAUDE_AGENT_IGNORE_TMPDIR=1
    #
    # Additional mitigations:
    #   1. Set CLAUDE_AGENT_IGNORE_TMPDIR=1 to ignore TMPDIR entirely (RECOMMENDED)
    #   2. Validate socket ownership with stat() before connecting
    #   3. Use only fixed prefixes by not setting TMPDIR
    #   4. Run in a restricted environment where TMPDIR cannot be manipulated
    #   5. Set TMPDIR to a trusted directory (e.g., /tmp) before process startup
    # Only allow TMPDIR when explicitly enabled via CLAUDE_AGENT_ALLOW_TMPDIR=1
    # This is opt-in for stricter security - TMPDIR could be attacker-controlled
    # SECURITY WARNING: NEVER set CLAUDE_AGENT_ALLOW_TMPDIR=1 in untrusted environments
    # or when an attacker could control environment variables before process startup.
    # An attacker could set both CLAUDE_AGENT_ALLOW_TMPDIR=1 and a malicious TMPDIR
    # to redirect socket connections to attacker-controlled locations.
    if ($ENV{TMPDIR} && $ENV{TMPDIR} =~ m{^/} && $ENV{CLAUDE_AGENT_ALLOW_TMPDIR}) {
        # SECURITY: Log warning when TMPDIR override is used
        warn "[SECURITY WARNING] TMPDIR-based socket path allowed via CLAUDE_AGENT_ALLOW_TMPDIR. "
            . "This is insecure if an attacker can control environment variables.\n"
            unless $ENV{CLAUDE_AGENT_QUIET_SECURITY_WARNINGS};
        push @allowed_prefixes, $ENV{TMPDIR};
        push @allowed_prefixes, "$ENV{TMPDIR}/" unless $ENV{TMPDIR} =~ m{/$};
    }

    require Cwd;
    my $resolved_path = Cwd::abs_path($socket_path);
    die "Invalid socket path: cannot resolve\n" unless defined $resolved_path;
    for my $prefix (@allowed_prefixes) {
        my $resolved_prefix = Cwd::abs_path($prefix);
        next unless defined $resolved_prefix;
        if (index($resolved_path, $resolved_prefix) == 0) {
            $valid_socket_path = 1;
            last;
        }
    }
    die "Invalid socket path: must be within a temporary directory (/tmp, /var/tmp, TMPDIR, etc.)\n"
        unless $valid_socket_path;

    # Validate server_name - alphanumeric with hyphens/underscores only
    die "Invalid server name: must be alphanumeric with hyphens/underscores\n"
        unless $server_name =~ /^[a-zA-Z0-9_-]{1,100}$/;

    # Validate version if provided - semver-like format
    die "Invalid version format\n"
        if defined($version) && length($version) && $version !~ /^[a-zA-Z0-9._-]{1,50}$/;

    # Limit tools_json size to prevent memory exhaustion (1MB limit)
    die "tools_json too large (max 1MB)\n" if length($tools_json) > 1_000_000;

    my ($tools) = $state->{jsonl}->decode($tools_json);

    # Validate decoded structure: must be an array of tool definitions
    die "Invalid tools_json: expected array\n" unless ref $tools eq 'ARRAY';
    for my $tool (@$tools) {
        die "Invalid tool definition: expected hash with 'name' key\n"
            unless ref $tool eq 'HASH' && defined $tool->{name};
    }

    # Build tool lookup
    my %tool_by_name = map { $_->{name} => $_ } @$tools;

    # Validate socket ownership before connecting (defense-in-depth)
    # This helps detect if an attacker has replaced the socket with one they control
    {
        my @stat_info = stat($socket_path);
        if (@stat_info) {
            my $socket_uid = $stat_info[4];
            if ($socket_uid != $<) {
                die "Security error: socket '$socket_path' is owned by uid $socket_uid, expected uid $< (current user)\n";
            }
        }
        # If stat fails, the socket may not exist yet - let the connect() call handle it
    }

    # Connect to parent socket
    $state->{socket} = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $socket_path,
    ) or die "Cannot connect to socket $socket_path: $!\n";

    $state->{socket}->autoflush(1);

    $log->debug(sprintf("SDKRunner: Initializing with socket: %s", $socket_path));
    $log->debug("SDKRunner: Connected to parent socket");

    # Create IO::Async event loop
    $state->{loop} = IO::Async::Loop->new;

    # Track running state
    my $running = 1;

    # Shutdown helper
    my $shutdown = sub {
        return unless $running;
        $running = 0;
        $state->{loop}->stop;
    };

    # Handle signals for graceful shutdown
    local $SIG{TERM} = $shutdown;
    local $SIG{PIPE} = $shutdown;

    # Create async stream for STDIN (from Claude CLI)
    my $stdin_stream = IO::Async::Stream->new(
        read_handle => \*STDIN,
        on_read => sub {
            my ($stream, $buffref) = @_;

            while ($$buffref =~ s/^([^\n]+)\n//) {
                my $line = $1;
                next unless length $line;

                $log->trace(sprintf("SDKRunner: Received: %s", $line));

                my @requests;
                my $parse_error;
                try {
                    @requests = $state->{jsonl}->decode($line);
                } catch {
                    $parse_error = $_;
                };
                if ($parse_error) {
                    $log->warning(sprintf("SDKRunner: Failed to parse JSON: %s", $parse_error));
                    next;
                }

                for my $request (@requests) {
                    my $response = handle_mcp_request(
                        $request, \%tool_by_name, $server_name, $version, $tools
                    );

                    if ($response) {
                        my $json = $state->{jsonl}->encode([$response]);
                        $log->trace(sprintf("SDKRunner: Sending: %s", $json));
                        print $json;
                        STDOUT->flush();
                    }
                }
            }
            return 0;
        },
        on_read_eof => sub {
            $log->debug("SDKRunner: STDIN closed (EOF)");
            $shutdown->();
        },
        on_read_error => sub {
            my ($stream, $errno) = @_;
            $log->debug(sprintf("SDKRunner: STDIN read error: %s", $errno));
            $shutdown->();
        },
    );

    # Create async stream for socket (to parent SDKServer)
    # Used for async writes and monitoring disconnection
    # Response reads are handled via $state->{response_buffer}/$state->{got_response}
    # which call_parent_handler uses with loop_once() polling
    $state->{socket_stream} = IO::Async::Stream->new(
        handle => $state->{socket},
        on_read => sub {
            my ($stream, $buffref) = @_;
            # Buffer incoming data for call_parent_handler to consume
            $state->{response_buffer} .= $$buffref;
            $$buffref = '';
            # Check if we have a complete line
            if ($state->{response_buffer} =~ /\n/) {
                $state->{got_response} = 1;
            }
            return 0;
        },
        on_read_eof => sub {
            $log->debug("SDKRunner: Socket closed by parent");
            $shutdown->();
        },
        on_read_error => sub {
            my ($stream, $errno) = @_;
            $log->debug(sprintf("SDKRunner: Socket error: %s", $errno));
            $shutdown->();
        },
    );

    $state->{loop}->add($stdin_stream);
    $state->{loop}->add($state->{socket_stream});

    $log->debug("SDKRunner: Starting event loop");

    # Run the event loop
    $state->{loop}->run;

    $log->debug("SDKRunner: Event loop stopped");

    # Cleanup
    $log->debug("SDKRunner: Closing socket connection");
    $state->{loop}->remove($stdin_stream) if $stdin_stream;
    $state->{loop}->remove($state->{socket_stream}) if $state->{socket_stream};
    $state->{socket}->close() if $state->{socket};
    return;
}

sub handle_mcp_request {
    my ($request, $tool_by_name, $server_name, $version, $tools) = @_;

    my $method = $request->{method} // '';
    my $id     = $request->{id};
    my $params = $request->{params} // {};

    $log->debug(sprintf("SDKRunner: Handling MCP request method=%s id=%s", $method, $id // 'none'));

    # Handle MCP protocol methods
    if ($method eq 'initialize') {
        return {
            jsonrpc => '2.0',
            id      => $id,
            result  => {
                protocolVersion => '2024-11-05',
                capabilities    => {
                    tools => {},
                },
                serverInfo => {
                    name    => $server_name,
                    version => $version,
                },
            },
        };
    }
    elsif ($method eq 'notifications/initialized') {
        # No response needed for notification
        return;
    }
    elsif ($method eq 'tools/list') {
        my @tool_list;
        for my $tool (@$tools) {
            push @tool_list, {
                name        => $tool->{name},
                description => $tool->{description},
                inputSchema => $tool->{input_schema},
            };
        }
        return {
            jsonrpc => '2.0',
            id      => $id,
            result  => {
                tools => \@tool_list,
            },
        };
    }
    elsif ($method eq 'tools/call') {
        my $tool_name = $params->{name};
        my $arguments = $params->{arguments} // {};

        $log->debug(sprintf("SDKRunner: Forwarding tools/call for tool=%s", $tool_name // 'none'));

        my $tool = $tool_by_name->{$tool_name};
        unless ($tool) {
            # Sanitize tool name in error message (truncate, remove control chars)
            my $safe_name = defined $tool_name ? substr($tool_name, 0, 100) : '<undefined>';
            $safe_name =~ s/[[:cntrl:]]//g;
            return {
                jsonrpc => '2.0',
                id      => $id,
                error   => {
                    code    => -32601,
                    message => "Unknown tool: $safe_name",
                },
            };
        }

        # Forward tool call to parent via socket
        my $result = call_parent_handler($tool_name, $arguments);

        return {
            jsonrpc => '2.0',
            id      => $id,
            result  => {
                content => $result->{content} // [],
                isError => $result->{isError} // \0,
            },
        };
    }
    elsif ($method eq 'ping') {
        return {
            jsonrpc => '2.0',
            id      => $id,
            result  => {},
        };
    }

    # Unknown method
    my $safe_method = defined $method ? substr($method, 0, 100) : '<undefined>';
    $safe_method =~ s/[[:cntrl:]]//g;
    return {
        jsonrpc => '2.0',
        id      => $id,
        error   => {
            code    => -32601,
            message => "Method not found: $safe_method",
        },
    };
}

sub _generate_uuid {
    # Generate a UUID v4-like string to avoid request ID collisions
    # Uses cryptographically secure random bytes for robust uniqueness
    require Crypt::URandom;
    my $random_bytes = Crypt::URandom::urandom(16);
    my $uuid = unpack('H*', $random_bytes);
    $uuid =~ s/(.{8})(.{4})(.{4})(.{4})(.{12})/$1-$2-$3-$4-$5/;
    return $uuid;
}

sub call_parent_handler {
    my ($tool_name, $args) = @_;

    # Use UUID-based request IDs to eliminate any possibility of ID collision
    # even if async/threaded handling is added in the future
    my $request_id = _generate_uuid();

    # Send request to parent via async stream
    my $request = $state->{jsonl}->encode([{
        id   => $request_id,
        tool => $tool_name,
        args => $args,
    }]);

    $log->debug(sprintf("SDKRunner: Sending request to parent id=%s", $request_id));
    $log->trace(sprintf("SDKRunner: Request payload: %s", $request));

    $state->{socket_stream}->write($request);

    # Reset response flag before waiting
    $state->{got_response} = 0;

    # Wait for response with configurable timeout using actual elapsed time
    require Time::HiRes;
    my $timeout = $ENV{CLAUDE_AGENT_TOOL_TIMEOUT} // 60;
    my $max_timeout = 300;
    # Ensure numeric value between 1-300 seconds (1 sec to 5 minutes)
    # Non-numeric, empty, zero, or out-of-range values fall back to 60s default
    # Security note: Lower maximum (300s) prevents resource exhaustion attacks.
    # For operations requiring longer timeouts, consider breaking them into smaller steps.
    if (!defined $timeout || $timeout !~ /^\d+$/ || $timeout < 1) {
        $timeout = 60;
    } elsif ($timeout > $max_timeout) {
        $log->warning(sprintf("CLAUDE_AGENT_TOOL_TIMEOUT=%d exceeds maximum (%d seconds), capping to %d seconds",
            $timeout, $max_timeout, $max_timeout));
        $timeout = $max_timeout;
    }
    my $start_time = Time::HiRes::time();
    my $backoff = 0.1;
    my $last_buffer_size = length($state->{response_buffer});
    my $stall_count = 0;
    my $max_stall_iterations = 100;  # ~10 seconds at max backoff before declaring stall

    while (!$state->{got_response}) {
        # Check elapsed time before loop_once to ensure accurate timeout enforcement
        my $elapsed = Time::HiRes::time() - $start_time;
        last if $elapsed >= $timeout;

        $state->{loop}->loop_once($backoff);
        $backoff = $backoff * 1.5 if $backoff < 1.0;  # Exponential backoff up to 1 second

        # Detect buffer growth without complete JSON lines (malformed/incomplete data)
        # Use tiered limits to detect issues early before memory spikes
        my $current_buffer_size = length($state->{response_buffer});
        my $warn_buffer_size = 5_000_000;   # 5MB warning threshold
        my $max_buffer_size = 10_000_000;   # 10MB hard limit
        if ($current_buffer_size > $max_buffer_size) {
            $log->debug(sprintf("SDKRunner: Buffer overflow (size: %d bytes), aborting", $current_buffer_size));
            # Clear buffer to reclaim memory before returning error
            $state->{response_buffer} = '';
            last;
        }
        elsif ($current_buffer_size > $warn_buffer_size) {
            # Log warning at 5MB to alert before hitting hard limit
            $log->debug(sprintf("SDKRunner: Buffer approaching limit (size: %d bytes, limit: %d)",
                $current_buffer_size, $max_buffer_size));
        }
        if ($current_buffer_size > 0 && $current_buffer_size == $last_buffer_size) {
            $stall_count++;
            if ($stall_count >= $max_stall_iterations) {
                $log->debug(sprintf("SDKRunner: Buffer stalled with incomplete data (size: %d)",
                    $current_buffer_size));
                last;
            }
        } elsif ($current_buffer_size != $last_buffer_size) {
            # Buffer changed - reset stall counter but don't reset backoff
            $stall_count = 0;
            $last_buffer_size = $current_buffer_size;
        }

        # Re-check elapsed time after loop_once in case it took longer than expected
        last if (Time::HiRes::time() - $start_time) >= $timeout;
    }

    # Extract the response line from buffer, matching by request ID
    my $response_line;
    # First check if we have a pending response for this request ID (from previous calls)
    # NOTE: pending_responses is initialized in reset_state() which is called at start of run().
    # Always verify initialization to catch bugs early - uninitialized state indicates
    # reset_state() was not called properly, which is a programming error.
    if (!defined $state->{pending_responses}) {
        require Carp;
        Carp::croak("BUG: pending_responses not initialized - reset_state() was not called properly. "
            . "This is a programming error that must be fixed.");
    }
    if (exists $state->{pending_responses}{$request_id}) {
        my $pending = delete $state->{pending_responses}{$request_id};
        $response_line = $pending->{line};
    }
    else {
        # Parse all complete lines and find matching response by ID
        # Store unmatched responses in a hash keyed by request ID for efficient lookup
        while ($state->{response_buffer} =~ s/^(.+)\n//) {
            my $line = $1;
            my ($resp, $parse_err);
            try {
                ($resp) = $state->{jsonl}->decode($line);
            } catch {
                $parse_err = $_;
            };
            if ($parse_err || !$resp) {
                # Log unparseable lines at debug level to aid troubleshooting
                $log->debug(sprintf("SDKRunner: Failed to parse buffered line (discarding): %s", $line));
                next;
            }
            if ($resp->{id} && $resp->{id} eq $request_id) {
                $response_line = $line;
                last;
            }
            # Store unmatched responses in hash keyed by ID for later retrieval
            # This avoids buffer corruption from re-joining partial data
            if ($resp->{id}) {
                $state->{pending_responses}{$resp->{id}} = { line => $line, resp => $resp };
            }
        }
    }
    # Reset flag if no more complete lines
    $state->{got_response} = 0 unless $state->{response_buffer} =~ /\n/;

    unless ($response_line) {
        $log->debug(sprintf("SDKRunner: Request timeout for id=%s after %ds", $request_id, $timeout));
        return {
            content => [{ type => 'text', text => 'No response from handler (timeout)' }],
            isError => \1,
        };
    }

    $log->debug(sprintf("SDKRunner: Received response for id=%s", $request_id));
    $log->trace(sprintf("SDKRunner: Response payload: %s", $response_line));

    my ($response, $parse_error);
    try {
        ($response) = $state->{jsonl}->decode($response_line);
    } catch {
        $parse_error = $_;
    };
    if ($parse_error) {
        $log->debug(sprintf("SDKRunner: Failed to parse response: %s", $parse_error));
        return {
            content => [{ type => 'text', text => 'Failed to parse handler response' }],
            isError => \1,
        };
    }

    return $response;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
