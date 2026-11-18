package API::Docker::API::System;
# ABSTRACT: Docker Engine System API
our $VERSION = '0.006';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::RegistryAuth',
  'API::Docker::Role::Using';
use Carp qw( croak );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


sub info {
  my ($self) = @_;
  return $self->client->get('/info',
    %{ $self->_request_options },
  );
}


sub version {
  my ($self) = @_;
  return $self->client->get('/version',
    %{ $self->_request_options },
  );
}


sub ping {
  my ($self) = @_;
  return $self->client->get('/_ping',
    %{ $self->_request_options },
  );
}


sub events {
  my ($self, %opts) = @_;
  my %params;
  $params{since}   = $opts{since}   if defined $opts{since};
  $params{until}   = $opts{until}   if defined $opts{until};
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  # croak_on_error => 0: /events is a feed, not the progress of one
  # operation. An object in it describes something that happened on the
  # engine, so it is data even if it ever carries an errorDetail key -- this
  # call must never croak on ordinary event traffic. It holds for the
  # callback path too, where the check would otherwise run per event.
  #
  # exists, not truth: `on_event => $cb` with an unset $cb is a caller bug,
  # and falling back to the buffered path for it would answer an unbounded
  # feed by hanging. Handed over as it is, the transport says so instead.
  return $self->client->get('/events',
    params         => \%params,
    croak_on_error => 0,
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $opts{on_event} ) : ( ndjson => 1 ),
  );
}


sub df {
  my ($self) = @_;
  return $self->client->get('/system/df',
    %{ $self->_request_options },
  );
}


sub auth {
  my ($self, %opts) = @_;

  # Two spellings of the same AuthConfig. The credential keys and the name
  # `auth` cannot collide -- the engine's AuthConfig has no `auth` field --
  # so both are accepted, but not at once: which one wins would be a silent
  # choice about someone's credentials.
  my @flat = grep { defined $opts{$_} }
    qw( username password email serveraddress identitytoken );
  croak __PACKAGE__ . '->auth takes either auth => $config or the credential '
    . 'keys themselves, not both (' . join(', ', @flat) . ' given beside auth)'
    if defined $opts{auth} && @flat;

  my $config = defined $opts{auth}
    ? $self->_registry_auth_config($opts{auth})
    : { map { $_ => $opts{$_} } @flat };

  # Stricter than the engine, deliberately. An empty AuthConfig is a valid
  # body -- Podman answers it 500 'getting username and password: cannot
  # prompt for username without stdin' -- but a credential check with no
  # credentials in it is a caller bug, and answering it with the engine's
  # message would hide that.
  croak __PACKAGE__ . '->auth requires credentials: pass username/password, '
    . 'identitytoken, or auth => $config' unless keys %$config;

  return $self->client->post('/auth', $config,
    %{ $self->_request_options },
    (exists $opts{response} ? (response => $opts{response}) : ()));
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::System - Docker Engine System API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # System information
    my $info = $docker->system->info;
    say "Docker version: " . $info->{ServerVersion};

    # API version
    my $version = $docker->system->version;
    say "API version: " . $version->{ApiVersion};

    # Health check
    my $pong = $docker->system->ping;

    # Monitor events
    my $events = $docker->system->events(
        since => time() - 3600,
    );

    # Disk usage
    my $df = $docker->system->df;

    # Check registry credentials before doing the work that needs them
    my $login = $docker->system->auth(
        username      => 'me',
        password      => 'secret',
        serveraddress => 'ghcr.io',
    );
    say $login->{Status};   # Login Succeeded

=head1 DESCRIPTION

This module provides access to Docker system-level operations including daemon
information, version detection, health checks, and event monitoring.

Accessed via C<< $docker->system >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->system->using(read_timeout => 5) >>.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 info

    my $info = $system->info;

Get system-wide information about the Docker daemon.

Returns hashref with keys including:

=over

=item * C<ServerVersion> - Docker version

=item * C<Containers> - Total number of containers

=item * C<Images> - Total number of images

=item * C<Driver> - Storage driver

=item * C<MemTotal> - Total memory

=back

=head2 version

    my $version = $system->version;

Get version information about the Docker daemon and API.

Returns hashref with keys including C<ApiVersion>, C<Version>, C<GitCommit>,
C<GoVersion>, C<Os>, and C<Arch>.

=head2 ping

    my $pong = $system->ping;

Health check endpoint. Returns C<OK> string if daemon is responsive.

=head2 events

    my $events = $system->events(
        since   => 1234567890,
        until   => 1234567900,
        filters => { type => ['container'] },
    );

Get events from the Docker daemon. Returns an ArrayRef of events, one per
object in the engine's newline-delimited JSON stream, even when the stream
carried a single object.

Unlike C<< $docker->images->build >>, C<pull> and C<push>, this method never
croaks on the content of the stream. Those report the outcome of one
operation, so an C<errorDetail> object in their stream means that operation
failed; C</events> is a feed, and an object in it is a record of something
that happened on the engine, never a failure of this call. Only transport and
HTTP errors croak here.

B<Bound the window with C<until>, or pass C<on_event>.> Without a callback the
transport buffers the whole response before parsing, so an unbounded call
blocks until the daemon closes the connection, which for a live event stream
is never.

Options:

=over

=item * C<since> - Show events created since this timestamp

=item * C<until> - Show events created before this timestamp

=item * C<filters> - HashRef of filter name to ArrayRef of string values, e.g.
C<< { type => ['container', 'image'] } >>. Shape-checked and normalised by
L<API::Docker::Role::Filters>; the daemon validates the names here, so a
misspelt one is a failed request rather than a quiet no-match

=item * C<on_event> - CodeRef called with each event as it arrives, instead of
the ArrayRef being collected and returned; see below

=back

=head2 Following the feed

An unbounded C</events> is the endpoint this client could not use at all.
Pass C<on_event> and the events are handed over one at a time as the daemon
sends them:

    my $summary = $system->events(
        since    => time - 60,
        on_event => sub {
            my ($event, $stop) = @_;
            say $event->{status};
            $stop->() if $event->{status} eq 'destroy';
        },
    );

    $summary;   # { delivered => 12, stopped => 1 }

With a callback the return value is that summary HashRef, not the events:
C<delivered> is how many went to the callback, C<stopped> is 1 when the
callback ended the feed and 0 when the daemon did. Nothing is accumulated --
a feed that runs for a day must not cost memory in proportion to how long it
ran, and the callback has been handed every event already. See
L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

Measured against the rootless Podman socket (5.4.2, API 1.41): with C<since>
and no C<until>, this returned in 0.3 seconds as soon as the callback said
stop, where the same call without one was still running when it was killed
after 22 seconds.

The callback never croaks on the content of the feed either: C<croak_on_error>
is off here on both paths, for the reason above.

=head2 df

    my $usage = $system->df;

Get data usage information (disk usage by images, containers, and volumes).

Returns hashref with C<LayersSize>, C<Images>, C<Containers>, and C<Volumes> arrays.

=head2 auth

    my $login = $system->auth(
        username      => 'me',
        password      => 'secret',
        serveraddress => 'ghcr.io',
    );

    # Or hand over the same auth argument images->push takes
    $system->auth(auth => $auth);

Check a set of registry credentials against the registry, without pulling or
pushing anything. Returns the decoded C<< POST /auth >> response, a HashRef
with C<Status> (C<Login Succeeded>) and, where the registry issues one,
C<IdentityToken>.

B<Bad credentials croak.> The engine answers a failed check with an error
status, and the transport croaks on any status at or above 400, so a
successful return I<is> the answer -- there is no false value to test. That
is what makes this useful as a pre-flight check: call it before building and
tagging an image, and a stale credential fails the run where it is cheap
rather than halfway through a push.

To tell one failure from another, eval and read the status:

    my %res;
    eval { $docker->system->auth(auth => $auth, response => \%res); 1 }
      or do {
        die "registry rejected the credentials" if $res{status} == 401;
        die "could not reach the registry: $@";
      };

Options -- the AuthConfig keys the engine defines, all optional
individually, but at least one is required:

=over

=item * C<username> - Registry account name

=item * C<password> - Its password or token

=item * C<email> - Legacy field, accepted and ignored by current registries

=item * C<serveraddress> - Registry to check against, e.g. C<ghcr.io>.
Omitted, the engine uses its default registry

=item * C<identitytoken> - Bearer token, instead of username and password

=item * C<auth> - The whole AuthConfig at once, in any shape
L<API::Docker::API::Images/push> accepts it: a HashRef, a JSON object, or a
base64url-encoded one. Cannot be combined with the keys above

=item * C<response> - HashRef the status line and the response headers are
written into, as for L<API::Docker::Role::HTTP/get>

=back

Passing neither C<auth> nor any credential key croaks before the request is
made.

=head3 What Podman answers

Measured against the rootless Podman socket (5.4.2, API 1.41): the endpoint
exists, but a failed check is B<500 Internal Server Error>, not Docker's 401,
and the message is the registry's own text wrapped by Podman --
C<< {"message":"login attempt to 127.0.0.1:1 failed with status: ..."} >>.
An empty AuthConfig answers
C<< {"message":"login attempt to  failed with status: getting username and
password: cannot prompt for username without stdin"} >>, also 500. So the
croak is reliable on both engines while the status behind it is not: test the
outcome, not the number.

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
