package API::Docker::Role::HTTP;
# ABSTRACT: HTTP transport role for Docker Engine API
our $VERSION = '0.002';
use Moo::Role;
use IO::Socket::UNIX;
use IO::Socket::INET;
use JSON::MaybeXS qw( encode_json decode_json );
use Carp qw( croak );
use Log::Any qw( $log );
use namespace::clean;


requires 'host';
requires 'api_version';

has _socket => (
  is      => 'lazy',
  clearer => '_clear_socket',
);

sub _build__socket {
  my ($self) = @_;
  my $host = $self->host;

  if ($host =~ m{^unix://(.+)$}) {
    my $path = $1;
    $log->debugf("Connecting to Unix socket: %s", $path);
    my $sock = IO::Socket::UNIX->new(
      Peer => $path,
      Type => SOCK_STREAM,
    );
    croak "Cannot connect to Unix socket $path: $!" unless $sock;
    return $sock;
  }
  elsif ($host =~ m{^tcp://([^:]+):(\d+)$}) {
    my ($addr, $port) = ($1, $2);
    $log->debugf("Connecting to TCP %s:%s", $addr, $port);
    my $sock = IO::Socket::INET->new(
      PeerAddr => $addr,
      PeerPort => $port,
      Proto    => 'tcp',
    );
    croak "Cannot connect to $addr:$port: $!" unless $sock;
    return $sock;
  }
  else {
    croak "Unsupported host format: $host (expected unix:// or tcp://)";
  }
}

sub _reconnect {
  my ($self) = @_;
  $self->_clear_socket;
  return $self->_socket;
}

sub _request {
  my ($self, $method, $path, %opts) = @_;

  my $version = $self->api_version;
  my $url_path = defined $version ? "/v$version$path" : $path;

  my $body_content = '';
  my $content_type = 'application/json';
  if ($opts{raw_body}) {
    $body_content = $opts{raw_body};
    $content_type = $opts{content_type} // 'application/x-tar';
  }
  elsif ($opts{body}) {
    $body_content = encode_json($opts{body});
  }

  if ($opts{params}) {
    my @pairs;
    for my $k (sort keys %{$opts{params}}) {
      my $v = $opts{params}{$k};
      next unless defined $v;
      if (ref $v eq 'HASH') {
        $v = encode_json($v);
      }
      push @pairs, _uri_encode($k) . '=' . _uri_encode($v);
    }
    $url_path .= '?' . join('&', @pairs) if @pairs;
  }

  $log->debugf("%s %s", $method, $url_path);

  my $request = "$method $url_path HTTP/1.1\r\n";
  $request .= "Host: localhost\r\n";
  $request .= "Connection: close\r\n";
  $request .= "User-Agent: API-Docker\r\n";

  if ($body_content) {
    $request .= "Content-Type: $content_type\r\n";
    $request .= "Content-Length: " . length($body_content) . "\r\n";
  }

  if ($opts{headers}) {
    for my $h (sort keys %{$opts{headers}}) {
      my $v = $opts{headers}{$h};
      next unless defined $v;
      $v =~ s/[\r\n]//g;
      $request .= "$h: $v\r\n";
    }
  }

  $request .= "\r\n";
  $request .= $body_content if $body_content;

  my $sock = $self->_reconnect;
  print $sock $request;

  my $response = $self->_read_response($sock);
  close $sock;
  $self->_clear_socket;

  my ($status_code, $status_text, $headers, $body) = @$response;

  $log->debugf("Response: %s %s", $status_code, $status_text);

  if ($status_code >= 400) {
    my $error_msg = $body;
    if ($body && $body =~ /^\s*[\{\[]/) {
      eval {
        my $data = decode_json($body);
        $error_msg = $data->{message} // $body;
      };
    }
    croak "Docker API error ($status_code): $error_msg";
  }

  if ($status_code == 204 || !defined($body) || $body eq '') {
    return undef;
  }

  if ($body =~ /^\s*[\{\[]/) {
    my $result = eval { decode_json($body) };
    return $result if defined $result;

    # Streaming endpoints (e.g. /build, /images/create) return
    # newline-delimited JSON objects.  Parse each line separately.
    my @objects;
    for my $line (split /\r?\n/, $body) {
      next unless $line =~ /\S/;
      my $obj = eval { decode_json($line) };
      push @objects, $obj if defined $obj;
    }
    return \@objects if @objects;
  }

  return $body;
}

sub _read_response {
  my ($self, $sock) = @_;

  my $status_line = <$sock>;
  croak "No response from Docker daemon" unless defined $status_line;
  $status_line =~ s/\r?\n$//;

  my ($proto, $status_code, $status_text) = split /\s+/, $status_line, 3;

  my %headers;
  while (my $line = <$sock>) {
    $line =~ s/\r?\n$//;
    last if $line eq '';
    if ($line =~ /^([^:]+):\s*(.*)$/) {
      $headers{lc $1} = $2;
    }
  }

  my $body = '';
  if ($headers{'transfer-encoding'} && $headers{'transfer-encoding'} eq 'chunked') {
    $body = $self->_read_chunked($sock);
  }
  elsif (defined $headers{'content-length'}) {
    my $len = $headers{'content-length'};
    if ($len > 0) {
      my $read = 0;
      while ($read < $len) {
        my $buf;
        my $n = read($sock, $buf, $len - $read);
        last unless $n;
        $body .= $buf;
        $read += $n;
      }
    }
  }
  else {
    local $/;
    $body = <$sock> // '';
  }

  return [$status_code, $status_text, \%headers, $body];
}

sub _read_chunked {
  my ($self, $sock) = @_;
  my $body = '';

  while (1) {
    my $chunk_header = <$sock>;
    last unless defined $chunk_header;
    $chunk_header =~ s/\r?\n$//;
    my $chunk_size = hex($chunk_header);
    last if $chunk_size == 0;

    my $chunk = '';
    my $read = 0;
    while ($read < $chunk_size) {
      my $buf;
      my $n = read($sock, $buf, $chunk_size - $read);
      last unless $n;
      $chunk .= $buf;
      $read += $n;
    }
    $body .= $chunk;

    # Read trailing \r\n after chunk data
    <$sock>;
  }

  return $body;
}

sub _uri_encode {
  my ($str) = @_;
  $str =~ s/([^A-Za-z0-9\-_.~:\/])/sprintf("%%%02X", ord($1))/ge;
  return $str;
}

sub get {
  my ($self, $path, %opts) = @_;
  return $self->_request('GET', $path, %opts);
}


sub post {
  my ($self, $path, $body, %opts) = @_;
  $opts{body} = $body if defined $body;
  return $self->_request('POST', $path, %opts);
}


sub put {
  my ($self, $path, $body, %opts) = @_;
  $opts{body} = $body if defined $body;
  return $self->_request('PUT', $path, %opts);
}


sub delete_request {
  my ($self, $path, %opts) = @_;
  return $self->_request('DELETE', $path, %opts);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::HTTP - HTTP transport role for Docker Engine API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package MyDockerClient;
    use Moo;

    has host => (is => 'ro', required => 1);
    has api_version => (is => 'ro');

    with 'API::Docker::Role::HTTP';

    # Now use get, post, put, delete_request methods
    my $data = $self->get('/containers/json');

=head1 DESCRIPTION

This role provides HTTP transport for the Docker Engine API. It implements
HTTP/1.1 communication over Unix sockets and TCP sockets without depending on
heavy HTTP client libraries like LWP.

Features:

=over

=item * Unix socket transport (C<unix://...>)

=item * TCP socket transport (C<tcp://host:port>)

=item * HTTP/1.1 chunked transfer encoding

=item * Automatic JSON encoding/decoding

=item * Request/response logging via L<Log::Any>

=item * Automatic connection management

=back

Consuming classes must provide C<host> and C<api_version> attributes.

=head2 get

    my $data = $client->get($path, %opts);

Perform HTTP GET request. Returns decoded JSON or raw response body.

Options: C<params> (hashref of query parameters),
C<headers> (hashref of extra HTTP headers, e.g. C<< { 'X-Registry-Auth' => $b64 } >>).

=head2 post

    my $data = $client->post($path, $body, %opts);

Perform HTTP POST request. C<$body> is automatically JSON-encoded if provided.

Options: C<params> (hashref of query parameters),
C<headers> (hashref of extra HTTP headers).

=head2 put

    my $data = $client->put($path, $body, %opts);

Perform HTTP PUT request. C<$body> is automatically JSON-encoded if provided.

Options: C<params> (hashref of query parameters).

=head2 delete_request

    my $data = $client->delete_request($path, %opts);

Perform HTTP DELETE request.

Options: C<params> (hashref of query parameters).

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main client using this role

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
