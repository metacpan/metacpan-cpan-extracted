package Claude::Agent::MCP::SDKServer;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Logger '$log';
use Errno qw(ENOENT);
use IO::Socket::UNIX;
use JSON::Lines;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);
use Try::Tiny;

=head1 NAME

Claude::Agent::MCP::SDKServer - Socket-based MCP server for SDK tools

=head1 DESCRIPTION

This module manages the IPC between the Perl SDK and the MCP server runner.
It creates a Unix socket, spawns the runner as a stdio MCP server, and
handles tool call requests from the runner by executing the local handlers.

=head1 SYNOPSIS

    use Claude::Agent::MCP::SDKServer;

    my $sdk_server = Claude::Agent::MCP::SDKServer->new(
        server => $mcp_server,  # Claude::Agent::MCP::Server object
        loop   => $loop,        # IO::Async::Loop
    );

    # Get the stdio config for the CLI
    my $stdio_config = $sdk_server->to_stdio_config();

    # Start listening for tool calls
    $sdk_server->start();

=cut

use Types::Common -types;
use Marlin
    'server!',           # Claude::Agent::MCP::Server object
    'loop!',             # IO::Async::Loop
    '_socket_path==.',   # Path to Unix socket
    '_listener==.',      # IO::Async listener
    '_temp_dir==.',      # Temp directory for socket
    '_jsonl==.',         # JSON::Lines instance
    '_pending_futures==' => sub { {} },  # Track pending async futures to prevent GC
    '_future_counter==' => sub { 0 };    # Counter for generating unique future IDs

sub BUILD {
    my ($self) = @_;

    # Create temp directory for socket
    my $temp_dir = tempdir(CLEANUP => 1);
    $self->_temp_dir($temp_dir);

    # Use combination of PID, time, and cryptographic random for uniqueness
    require Crypt::URandom;
    my $random = unpack('L', Crypt::URandom::urandom(4)) % 100000;
    my $unique_suffix = sprintf("%d_%d_%d", $$, time(), $random);
    my $socket_path = File::Spec->catfile($temp_dir, "sdk_${unique_suffix}.sock");
    $self->_socket_path($socket_path);

    $self->_jsonl(JSON::Lines->new);
    return;
}

=head2 socket_path

Returns the path to the Unix socket.

=cut

sub socket_path {
    my ($self) = @_;
    return $self->_socket_path;
}

=head2 to_stdio_config

Returns a hashref suitable for use as a stdio MCP server config.

B<Security Note:> The PERL5LIB environment variable is automatically
filtered from @INC paths to include only known safe Perl library directories.
Symlinks within permitted directory prefixes are rejected by default for security.

B<============================================================================>

B<SECURITY WARNING FOR PRODUCTION/MULTI-TENANT ENVIRONMENTS>

B<============================================================================>

Symlinks within allowed directories (e.g., /Users/attacker/perl5/) could
be exploited to inject malicious Perl libraries. For this reason, symlinks
are B<rejected by default>.

B<Symlink handling options:>

    # Symlinks are REJECTED by default (secure)

    # To allow symlinks (NOT recommended for production):
    $ENV{CLAUDE_AGENT_PERL5LIB_ALLOW_SYMLINKS} = 1;

    # Alternative: Set PERL5LIB explicitly to trusted paths only:
    $ENV{PERL5LIB} = '/path/to/trusted/lib:/path/to/other/lib';

The default behavior rejects any library paths that are symlinks, preventing
potential library injection attacks. Only set C<CLAUDE_AGENT_PERL5LIB_ALLOW_SYMLINKS=1>
if you have verified that all symlinks in your PERL5LIB paths are trusted.

=cut

sub to_stdio_config {
    my ($self) = @_;

    # Build tool definitions for the runner
    my @tools;
    for my $tool (@{$self->server->tools}) {
        push @tools, {
            name         => $tool->name,
            description  => $tool->description,
            input_schema => $tool->input_schema,
        };
    }

    # Encode tools as a single JSON array (not JSON Lines format)
    # We pass [[\@tools]] to get a single line containing the array
    my $tools_json = $self->_jsonl->encode([\@tools]);
    chomp $tools_json;

    return {
        type    => 'stdio',
        command => $^X,  # Current Perl interpreter
        args    => [
            '-MClaude::Agent::MCP::SDKRunner',
            '-e',
            'Claude::Agent::MCP::SDKRunner::run()',
            '--',
            $self->_socket_path,
            $self->server->name,
            $self->server->version,
            $tools_json,
        ],
        env => {
            # Use strict allowlist approach for PERL5LIB - only include known safe paths
            # This avoids complex symlink/traversal filtering that could be bypassed
            # Note: We limit to first 20 @INC entries to prevent overly long PERL5LIB
            # (typical installations have 5-15 entries; 20 is generous while bounding input)
            # Security: abs_path resolves symlinks, but paths within allowed prefixes
            # could still contain symlinks. The allowlist restricts to known Perl lib
            # directories where symlink attacks are less likely to be meaningful.
            # WARNING: Symlinks within allowed prefixes are permitted.
            # For untrusted environments, set PERL5LIB explicitly.
            # KNOWN LIMITATION: This is documented behavior - symlinks within allowed
            # directories are permitted. lstat-based validation to detect symlinks was
            # considered but rejected: (1) it adds complexity, (2) symlinks are often
            # legitimate (e.g., local::lib setups), (3) TOCTOU race remains possible.
            # For high-security or multi-tenant environments, set PERL5LIB explicitly:
            # $ENV{PERL5LIB} = '/path/to/trusted/lib:/path/to/other/lib';
            # See POD documentation for security recommendations.
            #
            # SECURITY WARNING (multi-tenant): In multi-tenant environments, symlinks
            # within allowed prefixes could be exploited to inject malicious libraries.
            # Set PERL5LIB explicitly or use CLAUDE_AGENT_PERL5LIB_STRICT=1 to reject symlinks.
            PERL5LIB => join(':', grep {
                my $path = $_;
                # Must be defined, absolute, and an existing directory
                defined $path && $path =~ m{^/} && -d $path && do {
                    require Cwd;
                    my $real = Cwd::abs_path($path);
                    # Verify canonicalized path doesn't escape allowed prefixes
                    $real = File::Spec->canonpath($real) if $real;
                    # Double-check the resolved path exists
                    defined $real && $real =~ m{^/} && -d $real
                        # Reject symlinks by default to prevent injection attacks in multi-tenant environments
                        # Set CLAUDE_AGENT_PERL5LIB_ALLOW_SYMLINKS=1 to allow symlinks (not recommended)
                        && do {
                            if (-l $path && $ENV{CLAUDE_AGENT_PERL5LIB_ALLOW_SYMLINKS}) {
                                # Symlinks explicitly allowed - log warning unless quieted
                                # SECURITY WARNING: DO NOT set CLAUDE_AGENT_PERL5LIB_ALLOW_SYMLINKS=1 in production
                                # or multi-tenant environments. Symlinks can enable library injection attacks.
                                $log->warning("[SECURITY] Symlink allowed in PERL5LIB path (CLAUDE_AGENT_PERL5LIB_ALLOW_SYMLINKS=1). "
                                    . "WARNING: This is insecure for production/multi-tenant environments!")
                                    unless $ENV{CLAUDE_AGENT_PERL5LIB_QUIET};
                                1;  # Allow with warning
                            } elsif (-l $path) {
                                # Default: reject symlinks for security (prevents library injection)
                                $log->warning("[SECURITY] Symlink rejected in PERL5LIB path (set CLAUDE_AGENT_PERL5LIB_ALLOW_SYMLINKS=1 to allow)")
                                    unless $ENV{CLAUDE_AGENT_PERL5LIB_QUIET};
                                0;  # Reject symlinks by default
                            } else {
                                1;  # Not a symlink, allow
                            }
                        }
                        # Use File::Spec->no_upwards equivalent check on path components
                        && do {
                            my @parts = File::Spec->splitdir($real);
                            # Reject if any component is '.' or '..'
                            !grep { $_ eq '.' || $_ eq '..' } @parts
                        }
                        # Restrict to known safe prefixes (standard Perl lib locations)
                        && ($real =~ m{^/usr/(?:local/)?(?:lib|share)/perl}
                            || $real =~ m{^/opt/local/lib/perl\d*/}
                            || $real =~ m{^/opt/perl\d*/lib/}
                            || $real =~ m{^/home/[^/]+/perl5/}
                            || $real =~ m{^/Users/[^/]+/perl5/}
                            # Validate HOME is a legitimate user directory before using
                            || ($ENV{HOME} && $ENV{HOME} =~ m{^/(home|Users)/[a-zA-Z0-9_-]+/?$} && $real =~ m{^\Q$ENV{HOME}\E/perl5/})
                            # Allow /lib within current working directory (for local development)
                            # This is more restrictive than generic /lib$ pattern
                            || (defined $ENV{PWD} && $real =~ m{^\Q$ENV{PWD}\E/(?:blib/)?lib$})
                            || $real =~ m{/blib/lib$}
                        )
                }
            } @INC[0 .. ($#INC > 19 ? 19 : $#INC)]),
        },
    };
}

=head2 start

Start listening on the Unix socket for tool call requests.

B<Concurrent Request Handling:> When multiple connections send requests
concurrently, responses may be interleaved and delivered in any order.
Clients MUST correlate responses using the C<id> field from each response,
which matches the C<id> from the corresponding request. Do not assume
responses arrive in request order.

=cut

sub start {
    my ($self) = @_;

    require IO::Async::Listener;
    require IO::Async::Stream;

    $log->debug(sprintf("SDKServer: Starting listener on socket: %s", $self->_socket_path));

    # Just attempt to start the listener - let it fail with a clear error
    # rather than pre-checking which has a TOCTOU race condition

    my $listener = IO::Async::Listener->new(
        on_stream => sub {
            my ($listener, $stream) = @_;

            $log->debug("SDKServer: New connection accepted");

            $stream->configure(
                on_read => sub {
                    my ($stream, $buffref) = @_;

                    while ($$buffref =~ s/^([^\n]+)\n//) {
                        my $line = $1;
                        $self->_handle_request($stream, $line);
                    }
                    return 0;
                },
            );

            $self->loop->add($stream);
        },
    );

    $self->loop->add($listener);

    try {
        $listener->listen(
            addr => {
                family   => 'unix',
                socktype => 'stream',
                path     => $self->_socket_path,
            },
        )->get;
    } catch {
        $self->loop->remove($listener);
        die "Failed to start SDK server listener: $_";
    };

    $self->_listener($listener);
    $log->debug("SDKServer: Listener ready, accepting connections");

    return $self;
}

sub _handle_request {
    my ($self, $stream, $line) = @_;

    # Note: Multiple concurrent requests from different connections may result
    # in interleaved responses. Response ordering relies on client-side correlation
    # using the request_id field. Each response includes the id from its corresponding
    # request for proper matching.

    my @requests;
    my $parse_error;
    try {
        @requests = $self->_jsonl->decode($line);
    } catch {
        $parse_error = $_;
    };

    if ($parse_error) {
        $log->debug(sprintf("SDKServer: Failed to parse request: %s", $parse_error));
        # Use generic error message to avoid leaking sensitive data
        my $error_response = $self->_jsonl->encode([{
            id      => undef,
            content => [{ type => 'text', text => 'Invalid JSON request' }],
            isError => \1,
        }]);
        $stream->write($error_response);
        return;
    }

    for my $request (@requests) {
        my $tool_name = $request->{tool};
        my $args      = $request->{args} // {};
        my $request_id = $request->{id};

        $log->debug(sprintf("SDKServer: Received request id=%s tool=%s", $request_id // 'none', $tool_name // 'none'));

        # Find and execute the tool
        my $tool = $self->server->get_tool($tool_name);

        my $result_future;
        if ($tool) {
            # execute() now returns a Future (sync handlers are auto-wrapped)
            $result_future = $tool->execute($args, $self->loop);
        }
        else {
            # Sanitize tool name in error message (truncate, remove control chars)
            my $safe_name = defined $tool_name ? substr($tool_name, 0, 100) : '<undefined>';
            $safe_name =~ s/[[:cntrl:]]//g;
            require Future;
            $result_future = Future->done({
                content  => [{ type => 'text', text => "Unknown tool: $safe_name" }],
                is_error => 1,
            });
        }

        # Generate unique ID for tracking this future
        my $count = $self->_future_counter + 1;
        $self->_future_counter($count);
        my $future_id = "$request_id-$count";

        $log->debug(sprintf("SDKServer: Tool %s execution started", $tool_name // 'unknown'));

        # Chain with then() to properly handle async completion
        # and store reference to prevent garbage collection
        my $chained = $result_future->then(sub {
            my ($result) = @_;

            $log->debug(sprintf("SDKServer: Tool %s execution completed", $tool_name // 'unknown'));

            # Validate result structure: must be hash with content as array
            my $valid = ref $result eq 'HASH' && ref($result->{content}) eq 'ARRAY';
            if ($valid) {
                for my $block (@{$result->{content}}) {
                    unless (ref $block eq 'HASH' && defined $block->{type}) {
                        $valid = 0;
                        last;
                    }
                }
            }
            unless ($valid) {
                $result = {
                    content  => [{ type => 'text', text => 'Invalid handler result format' }],
                    is_error => 1,
                };
            }

            # Send response back
            my $response = $self->_jsonl->encode([{
                id      => $request_id,
                content => $result->{content} // [],
                isError => $result->{is_error} ? \1 : \0,
            }]);

            $log->debug(sprintf("SDKServer: Sending response for request id=%s", $request_id // 'none'));
            $stream->write($response);

            # Remove from pending futures
            delete $self->_pending_futures->{$future_id};

            return Future->done;
        });

        # Retain the chained future to prevent GC
        $self->_pending_futures->{$future_id} = $chained;
    }
    return;
}

=head2 stop

Stop the listener and clean up.

=cut

sub stop {
    my ($self) = @_;

    $log->debug("SDKServer: Stopping listener");

    if ($self->_listener) {
        $self->loop->remove($self->_listener);
        $self->_listener(undef);
    }

    # Unlink unconditionally - log non-ENOENT errors for debugging but don't die
    # This is consistent with start() error handling
    if (!unlink($self->_socket_path) && $! != ENOENT) {
        $log->debug(sprintf("SDKServer: Could not remove socket during stop: %s: %s",
            $self->_socket_path, $!));
    }

    $log->debug("SDKServer: Listener stopped, socket closed");
    return;
}

sub DEMOLISH {
    my ($self) = @_;
    # Defensive check: loop may be invalid during object destruction
    try {
        $self->stop() if $self->loop;
    } catch {
        $log->debug(sprintf("SDKServer DEMOLISH error: %s", $_));
    };
    return;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
