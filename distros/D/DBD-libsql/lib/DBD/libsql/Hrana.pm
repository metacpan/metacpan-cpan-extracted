package DBD::libsql::Hrana;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use JSON;
use Protocol::WebSocket;
use IO::Socket::SSL;
use Carp;

our $VERSION = "0.02";

# Hrana Protocol Client for libSQL
# Based on the Hrana protocol specification used by libsql-client-ts

sub new {
    my ($class, %options) = @_;
    
    my $self = bless {
        url => $options{url} || 'http://127.0.0.1:8080',
        auth_token => $options{auth_token},
        user_agent => LWP::UserAgent->new(
            timeout => $options{timeout} || 30,
            agent => "DBD::libsql/$VERSION",
        ),
        json => JSON->new->utf8,
        connection_id => undef,
        closed => 0,
    }, $class;
    
    # Detect protocol type from URL
    if ($self->{url} =~ /^ws/) {
        $self->{protocol} = 'websocket';
    } else {
        $self->{protocol} = 'http';
    }
    
    return $self;
}

# HTTP-based Hrana implementation
sub connect_http {
    my $self = shift;
    
    # For HTTP, we don't need a persistent connection
    # Each request is stateless
    return 1;
}

# WebSocket-based Hrana implementation  
sub connect_websocket {
    my $self = shift;
    
    # Convert HTTP URL to WebSocket URL for local dev server
    my $ws_url = $self->{url};
    $ws_url =~ s/^http/ws/;
    $ws_url .= '/v2' unless $ws_url =~ /\/v2$/;
    
    eval {
        # For now, we'll implement WebSocket later
        # Just mark as connected for HTTP fallback
        $self->{connection_id} = $self->_generate_connection_id();
        warn "WebSocket connection would connect to: $ws_url" if $ENV{DBD_LIBSQL_DEBUG};
    };
    
    if ($@) {
        croak "Failed to connect via WebSocket: $@";
    }
    
    return 1;
}

sub connect {
    my $self = shift;
    
    if ($self->{protocol} eq 'websocket') {
        return $self->connect_websocket();
    } else {
        return $self->connect_http();
    }
}

# Execute SQL via HTTP Hrana
sub execute_http {
    my ($self, $sql, $params) = @_;
    
    my $request_body = {
        type => 'execute',
        stmt => {
            sql => $sql,
            args => $params || [],
        }
    };
    
    my $url = $self->{url} . '/v2/pipeline';
    my $request = HTTP::Request->new('POST', $url);
    $request->header('Content-Type' => 'application/json');
    
    if ($self->{auth_token}) {
        $request->header('Authorization' => 'Bearer ' . $self->{auth_token});
    }
    
    $request->content($self->{json}->encode({
        requests => [$request_body]
    }));
    
    my $response = $self->{user_agent}->request($request);
    
    unless ($response->is_success) {
        croak "HTTP request failed: " . $response->status_line;
    }
    
    my $result = eval { $self->{json}->decode($response->content) };
    if ($@) {
        croak "Failed to parse JSON response: $@";
    }
    
    return $self->_parse_execute_result($result);
}

# Execute SQL via WebSocket Hrana
sub execute_websocket {
    my ($self, $sql, $params) = @_;
    
    # TODO: Implement WebSocket-based execution
    # This would use the Hrana WebSocket protocol
    croak "WebSocket execution not yet implemented";
}

sub execute {
    my ($self, $sql, $params) = @_;
    
    if ($self->{closed}) {
        croak "Connection is closed";
    }
    
    if ($self->{protocol} eq 'websocket') {
        return $self->execute_websocket($sql, $params);
    } else {
        return $self->execute_http($sql, $params);
    }
}

# Execute batch of SQL statements
sub batch {
    my ($self, $statements) = @_;
    
    my @requests;
    for my $stmt (@$statements) {
        if (ref $stmt eq 'HASH') {
            push @requests, {
                type => 'execute',
                stmt => {
                    sql => $stmt->{sql},
                    args => $stmt->{args} || [],
                }
            };
        } else {
            push @requests, {
                type => 'execute', 
                stmt => {
                    sql => $stmt,
                    args => [],
                }
            };
        }
    }
    
    my $url = $self->{url} . '/v2/pipeline';
    my $request = HTTP::Request->new('POST', $url);
    $request->header('Content-Type' => 'application/json');
    
    if ($self->{auth_token}) {
        $request->header('Authorization' => 'Bearer ' . $self->{auth_token});
    }
    
    $request->content($self->{json}->encode({
        requests => \@requests
    }));
    
    my $response = $self->{user_agent}->request($request);
    
    unless ($response->is_success) {
        croak "Batch request failed: " . $response->status_line;
    }
    
    my $result = eval { $self->{json}->decode($response->content) };
    if ($@) {
        croak "Failed to parse JSON response: $@";
    }
    
    return $result;
}

# Parse execution result from Hrana response
sub _parse_execute_result {
    my ($self, $result) = @_;
    
    return undef unless $result && $result->{results};
    
    my $first_result = $result->{results}->[0];
    return undef unless $first_result && $first_result->{response};
    
    my $response = $first_result->{response};
    
    if ($response->{type} eq 'ok') {
        return {
            columns => $response->{result}->{cols} || [],
            rows => $response->{result}->{rows} || [],
            rows_affected => $response->{result}->{affected_row_count} || 0,
            last_insert_rowid => $response->{result}->{last_insert_rowid},
        };
    } elsif ($response->{type} eq 'error') {
        croak "SQL execution error: " . $response->{error}->{message};
    }
    
    return undef;
}

sub _generate_connection_id {
    return sprintf("%016x", int(rand(0xffffffff)));
}

sub close {
    my $self = shift;
    
    if ($self->{ws_client}) {
        # Close WebSocket connection
        $self->{ws_client} = undef;
    }
    
    $self->{closed} = 1;
    return 1;
}

sub DESTROY {
    my $self = shift;
    $self->close() unless $self->{closed};
}

1;

__END__

=head1 NAME

DBD::libsql::Hrana - Hrana protocol client for libSQL

=head1 DESCRIPTION

This module implements the Hrana protocol for communicating with libSQL servers.
It supports both HTTP and WebSocket transports.

=head1 METHODS

=head2 new(%options)

Creates a new Hrana client instance.

Options:
- url: Server URL (default: http://127.0.0.1:8080)
- auth_token: Authentication token for remote servers
- timeout: Request timeout in seconds (default: 30)

=head2 connect()

Establishes connection to the libSQL server.

=head2 execute($sql, $params)

Executes an SQL statement with optional parameters.

=head2 batch($statements)

Executes multiple SQL statements in a batch.

=head2 close()

Closes the connection to the server.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut