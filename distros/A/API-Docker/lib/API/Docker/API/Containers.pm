package API::Docker::API::Containers;
# ABSTRACT: Docker Engine Containers API
our $VERSION = '0.006';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::Using',
  'API::Docker::Role::JSONBody';
use API::Docker::Error::HTTP;
use API::Docker::Role::Entity::Container;
use API::Docker::Type::ContainerInspectResponse;
use API::Docker::Type::ContainerSummary;
use Carp qw( croak shortmess );
use JSON::MaybeXS qw( decode_json );
use MIME::Base64 qw( decode_base64 );
use Scalar::Util qw( blessed );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


# The class is the caller's argument rather than a constant of this module:
# `list` and `inspect` are two definitions in the swagger and therefore two
# generated classes. Both carry the same convenience methods, composed by
# API::Docker::Role::Entity::Container -- see "The two container shapes".
#
# from_data, not new: this is a daemon response, and the two entry points of
# API::Docker::Role::Type read it differently. from_data takes the swagger's
# wire names and nothing else, so a key it has not heard of keeps its own
# spelling instead of being read as the Perl name of one it has, and a value
# that disagrees with the swagger costs its own field rather than the whole
# response. `client` is ours rather than the engine's, so it goes beside the
# data instead of into it.
sub _wrap {
  my ($self, $class, $data) = @_;
  return $class->from_data($data, client => $self->client);
}

sub _wrap_list {
  my ($self, $class, $list) = @_;
  return [ map { $self->_wrap($class, $_) } @$list ];
}

# A state-change endpoint answers 204 when it changed something and 304 when
# the container was already in the state asked for. Neither carries a body, so
# the return value of the request is undef either way and the two are
# indistinguishable from it. The status comes out through the `response`
# out-parameter (see API::Docker::Role::HTTP/"Reading the status line and the
# response headers") and becomes the documented 1/0.
sub _state_change {
  my ($self, $path, %opts) = @_;
  my %response;
  $self->client->post($path, undef, %opts, response => \%response);
  return 0 if defined $response{status} && $response{status} == 304;
  return 1;
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{all}     = $opts{all} ? 1 : 0  if defined $opts{all};
  $params{limit}   = $opts{limit}        if defined $opts{limit};
  $params{size}    = $opts{size} ? 1 : 0 if defined $opts{size};
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  my $result = $self->client->get('/containers/json',
    params => \%params,
    %{ $self->_request_options },
  );
  return $self->_wrap_list('API::Docker::Type::ContainerSummary', $result // []);
}


# The booleans of the container create body, from spec/v1.51.yaml: the
# ContainerConfig flags at the top level, and the HostConfig flags in the
# nested `HostConfig` object (its own plus the ones it inherits from
# Resources). The engine rejects a number for any of them, so 1/0 is
# normalised to a JSON boolean on the way out; a caller may still pass 1/0 or a
# JSON boolean and it goes out correctly either way.
my @CONTAINER_CONFIG_BOOLS = qw(
  ArgsEscaped AttachStderr AttachStdin AttachStdout NetworkDisabled
  OpenStdin StdinOnce Tty
);
my @HOST_CONFIG_BOOLS = qw(
  AutoRemove Init OomKillDisable Privileged PublishAllPorts ReadonlyRootfs
);

sub create {
  my ($self, %config) = @_;
  my %params;
  $params{name} = delete $config{name} if defined $config{name};
  $self->_json_bools(\%config, @CONTAINER_CONFIG_BOOLS);
  # Copy the nested HostConfig before touching it -- _json_bools mutates, and
  # the sub-object is still the caller's until this copy replaces it.
  if (ref $config{HostConfig} eq 'HASH') {
    my %host_config = %{ $config{HostConfig} };
    $self->_json_bools(\%host_config, @HOST_CONFIG_BOOLS);
    $config{HostConfig} = \%host_config;
  }
  my $result = $self->client->post('/containers/create', \%config, params => \%params);
  return $result;
}


sub inspect {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  my $result = $self->client->get("/containers/$id/json",
    %{ $self->_request_options },
  );
  return $self->_wrap('API::Docker::Type::ContainerInspectResponse', $result);
}


sub start {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->_state_change("/containers/$id/start",
    %{ $self->_request_options },
  );
}


sub stop {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{t}      = $opts{timeout} if defined $opts{timeout};
  $params{signal} = $opts{signal}  if defined $opts{signal};
  return $self->_state_change("/containers/$id/stop",
    params => \%params,
    %{ $self->_request_options },
  );
}


sub restart {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{t} = $opts{timeout} if defined $opts{timeout};
  return $self->_state_change("/containers/$id/restart",
    params => \%params,
    %{ $self->_request_options },
  );
}


sub kill {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{signal} = $opts{signal} if defined $opts{signal};
  return $self->client->post("/containers/$id/kill", undef,
    params => \%params,
    %{ $self->_request_options },
  );
}


sub remove {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{v}     = $opts{volumes} ? 1 : 0 if defined $opts{volumes};
  $params{force} = $opts{force} ? 1 : 0   if defined $opts{force};
  $params{link}  = $opts{link} ? 1 : 0    if defined $opts{link};
  return $self->client->delete_request("/containers/$id",
    params => \%params,
    %{ $self->_request_options },
  );
}


sub logs {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{follow}     = $opts{follow} ? 1 : 0 if defined $opts{follow};
  $params{stdout}     = defined $opts{stdout} ? ($opts{stdout} ? 1 : 0) : 1;
  $params{stderr}     = defined $opts{stderr} ? ($opts{stderr} ? 1 : 0) : 1;
  $params{since}      = $opts{since}      if defined $opts{since};
  $params{until}      = $opts{until}      if defined $opts{until};
  $params{timestamps} = $opts{timestamps} ? 1 : 0 if defined $opts{timestamps};
  $params{tail}       = $opts{tail}       if defined $opts{tail};
  # exists, not truth: an unset callback is a caller bug, and quietly falling
  # back to the buffered path for it would answer a follow with a hang.
  return $self->client->stream_frames('GET', "/containers/$id/logs",
    params => \%params,
    defined $opts{tty} ? ( tty => $opts{tty} ) : (),
    %{ $self->_request_options },
    exists $opts{on_frame} ? ( on_frame => $opts{on_frame} ) : (),
  );
}


# The guard behind attach's require_running, and a pre-flight check is all it
# is: it asks the engine what the container is doing now, and the container may
# still stop between that answer and the attach landing. That race is not
# closable from a client -- the engine offers no attach-if-running -- and the
# check earns its round trip anyway, because the condition it tests is exactly
# the condition that does the damage. Measured on Podman 5.4.2 (API 1.41) and
# Docker 29.7.2 (API 1.55), one container per row, each exiting with status 4:
#
#   attach to an ALREADY-EXITED container      Podman: status destroyed
#   attach while RUNNING, exits under the call Podman: status intact (4)
#   either of those                            Docker: status intact (4)
#
# So "running at the moment of the call" is the whole of the condition. A
# container that is still running when attach is sent stays safe even when it
# exits a millisecond later, which is why the pre-flight answer is worth having
# despite being one round trip stale.
#
# It fails open on anything it does not recognise: a State it cannot read is
# not evidence that the container is stopped, and a guard that is unsure must
# not be the thing that breaks a working call.
sub _assert_container_running {
  my ($self, $id) = @_;

  # A State the model could not use is one more shape the check does not
  # recognise, and it arrives as one: the generated classes type their fields
  # from the swagger, and a State that is not the object
  # ContainerInspectResponse declares -- the bare status string of the list
  # shape, say -- leaves ->state unset and keeps the raw value in
  # unknown_fields rather than taking the response down with it. So there is
  # nothing to catch here; an error that does reach this line, the daemon's
  # own 404 included, is the caller's and goes up.
  my $inspected = $self->inspect($id);

  # An API::Docker::Type::ContainerState, or undef where the daemon sent no
  # State at all -- which is the "does not recognise" case above, not a stopped
  # container.
  my $state = $inspected->state;
  return unless blessed($state) && defined $state->running;
  return if $state->running;

  my $status = $state->status;
  $status = 'not running' unless defined $status && length $status;

  croak __PACKAGE__ . '->attach refused: container ' . $id . ' is ' . $status
    . '. Attaching to a container that is not running destroys its exit status '
    . 'on Podman, irrecoverably -- the engine keeps no copy -- and with '
    . 'stream => 1 never returns on either engine. Read its output with logs() '
    . 'instead, or pass require_running => 0 to attach anyway';
}

sub attach {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;

  # Pre-flight, and deliberately before the request is built: the call itself
  # is what destroys the exit status, so a check made afterwards could only
  # report the loss rather than prevent it. Turned off it costs nothing at all,
  # not even the round trip.
  my $require_running
    = defined $opts{require_running} ? $opts{require_running} : 1;
  # The pre-flight is a request the caller never wrote, and one that hangs is
  # exactly what a bound was set to prevent -- so it carries the same one. It
  # does that by itself here: the check runs on $self, which is the clone
  # ->using returned when there was one (karr k74).
  $self->_assert_container_running($id) if $require_running;

  my %params;
  $params{stream} = $opts{stream} ? 1 : 0;
  $params{logs}   = defined $opts{logs}   ? ($opts{logs}   ? 1 : 0) : 1;
  $params{stdout} = defined $opts{stdout} ? ($opts{stdout} ? 1 : 0) : 1;
  $params{stderr} = defined $opts{stderr} ? ($opts{stderr} ? 1 : 0) : 1;
  $params{stdin}  = $opts{stdin} ? 1 : 0 if defined $opts{stdin};
  return $self->client->stream_frames('POST', "/containers/$id/attach",
    params => \%params,
    defined $opts{tty} ? ( tty => $opts{tty} ) : (),
    %{ $self->_request_options },
    exists $opts{on_frame} ? ( on_frame => $opts{on_frame} ) : (),
  );
}


sub top {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{ps_args} = $opts{ps_args} if defined $opts{ps_args};
  return $self->client->get("/containers/$id/top",
    params => \%params,
    %{ $self->_request_options },
  );
}


# The Podman compatibility path, and deliberately only that. Podman answers
# GET /containers/{id}/stats for a container that is not running with an error
# object inside a response it has already committed to 200 --
# {"cause":"container is stopped","message":"container is stopped",
# "response":500}, chunked, for the one-shot call and for stream => 1 alike
# (measured on Podman 5.4.2, API 1.41). Neither guard in the transport sees
# it: the >= 400 croak reads the status line, which says 200, and the stream
# check triggers on errorDetail, which this object does not carry. Docker
# 29.7.2 (API 1.55) answers the same call with a real, zero-filled reading and
# never produces this shape at all -- so this belongs here, next to the one
# endpoint and the one engine it was measured on, and not in Role::HTTP, where
# it would be a heuristic on daemon prose sitting under all twelve modules.
#
# All four clauses have to hold. The narrowness is the point, not an accident:
#
#   1. the status was 2xx. True by construction on both paths this guards:
#      _request croaks before returning for >= 400, and
#      _read_streaming_response reads such a body whole rather than handing it
#      to a callback, so nothing that failed the status line reaches here
#   2. the decoded value is a HashRef
#   3. it carries all three of cause, message and response, exactly
#      lower-cased. Never case-insensitively, and this is the counter-example
#      that fixes it: POST /containers/{id}/wait answers its SUCCESS case with
#      a top-level `Error` key -- Podman sends "Error":null on every wait --
#      so a rule matching /error/i would turn every successful wait into a
#      failure. Measured over fifteen read endpoints per engine and every
#      fixture in t/fixtures: no 2xx body on either engine carries even one of
#      these three lower-cased at the top level
#   4. `response` is a non-ref scalar reading as an integer >= 400. That is
#      what makes the rule self-evidencing rather than a guess about prose:
#      the object is an error because Podman says so inside it. Known miss:
#      Podman's GET /plugins answers {"cause":"","message":"Path ... is not
#      supported","response":0}, which clause 4 rejects -- but it arrives with
#      404 on the status line and the transport croaks it long before this
#      runs, so the miss goes in the conservative direction and costs nothing
#
# A bare {message => ...} deliberately does not trigger: that is the ordinary
# Docker error body, and treating one inside a 2xx as a failure would be a
# guess about prose rather than a reading of what the engine said.
sub _podman_error_object {
  my ($self, $value) = @_;

  return unless ref $value eq 'HASH';
  return unless exists $value->{cause}
    && exists $value->{message}
    && exists $value->{response};

  my $response = $value->{response};
  return if ref $response;
  return unless defined $response && $response =~ /\A[0-9]+\z/;
  return unless $response >= 400;

  return $value;
}

# API::Docker::Error::HTTP rather than ::Stream: the one-shot call is not a
# stream at all, so "Docker API stream error" would be the wrong sentence for
# it and ->events would be a fabricated list. What the caller wants instead is
# exactly what this class carries -- ->status for the code Podman named, and
# ->data for the object, whose `cause` key that attribute's own POD already
# points at. Two of its attributes are left at their defaults on this path, on
# purpose: ->reason, because the status line's reason phrase was "OK" and
# putting that on a 500 would mislead, and ->body, because the bytes were
# decoded by the transport before this check ever saw them.
sub _assert_no_podman_error {
  my ($self, $endpoint, $value) = @_;

  my $error = $self->_podman_error_object($value) or return $value;

  my $reason = $error->{message};
  $reason = $error->{cause}    unless defined $reason && length $reason;
  $reason = 'no message given' unless defined $reason && length $reason;
  # Carp appends no location to a message that already ends in a newline.
  $reason =~ s/\s+\z//;

  # The object goes into a variable first: `croak CLASS->new(...)` is indirect
  # object syntax and parses as CLASS->croak(new(...)). Carp hands a reference
  # straight back rather than decorating it, so the location is captured by
  # hand, naming the frame a croak of a plain string would have named.
  my $err = API::Docker::Error::HTTP->new(
    message  => 'Docker API error (' . $error->{response} . '): ' . $reason
      . ' -- reported inside a 200 response to ' . $endpoint,
    location => shortmess(''),
    status   => $error->{response},
    data     => $error,
  );
  croak $err;
}

sub stats {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my $stream = $opts{stream} ? 1 : 0;
  my %params = ( stream => $stream );
  # one-shot asks the engine not to wait for a second sampling cycle, which
  # only means anything to a single reading. It is sent for the one-shot call
  # alone, the way it always was, and never beside stream => 1.
  $params{'one-shot'} = 1 unless $stream;

  my $endpoint = 'GET /containers/' . $id . '/stats';

  # The guard has to sit on both sides of the callback split, because the same
  # body arrives either way: buffered it is the return value, streamed it goes
  # to the callback and is never returned at all. Wrapping puts the check in
  # front of the caller's callback, so no caller is handed the error object as
  # though it were a reading. Only a CodeRef is wrapped -- anything else is
  # passed through untouched, so the transport still raises its own "on_event
  # option must be a CodeRef" instead of this method dying on a closure it
  # built around a non-callback.
  my $on_event = $opts{on_event};
  if (exists $opts{on_event} && ref $on_event eq 'CODE') {
    my $cb = $on_event;
    $on_event = sub {
      my ($reading, $stop) = @_;
      $self->_assert_no_podman_error($endpoint, $reading);
      return $cb->($reading, $stop);
    };
  }

  my $result = $self->client->get("/containers/$id/stats",
    params => \%params,
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $on_event )
      : $stream            ? ( ndjson   => 1 )
      : (),
  );

  # A HashRef for the one-shot call and an ArrayRef of readings for
  # stream => 1 without a callback -- both are the buffered body and both can
  # be that error object. With a callback the return value is the summary
  # HashRef, which carries none of the three keys and passes untouched.
  $self->_assert_no_podman_error($endpoint, $_)
    for ref $result eq 'ARRAY' ? @$result : ($result);

  return $result;
}


sub changes {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  my $result = $self->client->get("/containers/$id/changes",
    %{ $self->_request_options },
  );
  # A container with nothing changed answers with a JSON null, which the
  # transport decodes to undef. Normalised here so the return is always
  # something a caller can iterate.
  return ref $result eq 'ARRAY' ? $result : [];
}


sub export {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->client->get("/containers/$id/export",
    raw => 1,
    %{ $self->_request_options },
  );
}


sub resize {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{h} = $opts{h} if defined $opts{h};
  $params{w} = $opts{w} if defined $opts{w};
  return $self->client->post("/containers/$id/resize", undef,
    params => \%params,
    %{ $self->_request_options },
  );
}


sub wait {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{condition} = $opts{condition} if defined $opts{condition};
  return $self->client->post("/containers/$id/wait", undef,
    params => \%params,
    %{ $self->_request_options },
  );
}


sub pause {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->_state_change("/containers/$id/pause",
    %{ $self->_request_options },
  );
}


sub unpause {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->_state_change("/containers/$id/unpause",
    %{ $self->_request_options },
  );
}


sub rename {
  my ($self, $id, $name) = @_;
  croak "Container ID required" unless $id;
  croak "New name required" unless $name;
  return $self->client->post("/containers/$id/rename", undef,
    params => { name => $name },
    %{ $self->_request_options },
  );
}


# The update body is Resources + RestartPolicy; the booleans are the two
# Resources flags. Normalised on the way out, as for create.
my @UPDATE_BOOLS = qw( Init OomKillDisable );

sub update {
  my ($self, $id, %config) = @_;
  croak "Container ID required" unless $id;
  $self->_json_bools(\%config, @UPDATE_BOOLS);
  return $self->client->post("/containers/$id/update", \%config);
}


# The engine reports what a path is in a response header rather than a body,
# so both GET and HEAD carry it and only HEAD has nothing else to say. The
# header is base64-encoded JSON; handing the caller the base64 would make
# every one of them write this.
sub _decode_path_stat {
  my ($self, $response) = @_;

  my $header = $response->{headers}{'x-docker-container-path-stat'};
  return undef unless defined $header && length $header;

  # Docker encodes this one with Go's base64.StdEncoding -- unlike
  # X-Registry-Auth, which is URLEncoding. Decoded tolerantly rather than
  # strictly: translating the two URL-safe characters first costs nothing and
  # means an engine that reached for the other alphabet is still read.
  $header =~ tr{-_}{+/};
  my $stat = eval { decode_json(decode_base64($header)) };
  croak "Cannot decode X-Docker-Container-Path-Stat header: $@"
    unless ref $stat eq 'HASH';

  return $stat;
}

sub get_archive {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  croak "Path required" unless defined $opts{path} && length $opts{path};
  croak "The stat option must be a HashRef"
    if exists $opts{stat} && ref $opts{stat} ne 'HASH';

  my %response;
  my $tar = $self->client->get("/containers/$id/archive",
    params   => { path => $opts{path} },
    raw      => 1,
    response => \%response,
    %{ $self->_request_options },
  );

  if (my $out = $opts{stat}) {
    %$out = %{ $self->_decode_path_stat(\%response) // {} };
  }

  return $tar;
}


sub put_archive {
  my ($self, $id, $tar, %opts) = @_;
  croak "Container ID required" unless $id;
  croak "Path required" unless defined $opts{path} && length $opts{path};
  croak "Tar archive required (raw bytes or a scalar ref)" unless defined $tar;

  my %params = ( path => $opts{path} );
  $params{noOverwriteDirNonDir} = $opts{noOverwriteDirNonDir} ? 1 : 0
    if defined $opts{noOverwriteDirNonDir};
  $params{copyUIDGID} = $opts{copyUIDGID} ? 1 : 0
    if defined $opts{copyUIDGID};

  my $raw = ref $tar eq 'SCALAR' ? $$tar : $tar;

  return $self->client->put("/containers/$id/archive", undef,
    params       => \%params,
    raw_body     => $raw,
    content_type => 'application/x-tar',
    %{ $self->_request_options },
  );
}


sub stat_archive {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  croak "Path required" unless defined $opts{path} && length $opts{path};

  my %response;
  $self->client->head("/containers/$id/archive",
    params   => { path => $opts{path} },
    response => \%response,
    %{ $self->_request_options },
  );

  return $self->_decode_path_stat(\%response);
}


sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->client->post('/containers/prune', undef,
    params => \%params,
    %{ $self->_request_options },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Containers - Docker Engine Containers API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # List containers
    my $containers = $docker->containers->list(all => 1);
    for my $container (@$containers) {
        say $container->id;
        say $container->status;
    }

    # Create and start a container
    my $result = $docker->containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
        ExposedPorts => { '80/tcp' => {} },
    );
    $docker->containers->start($result->{Id});

    # Inspect container details
    my $container = $docker->containers->inspect($result->{Id});
    say $container->name;

    # Stop and remove
    $docker->containers->stop($result->{Id}, timeout => 10);
    $docker->containers->remove($result->{Id});

    # View logs (ArrayRef of { stream => 'stdout'|'stderr'|'raw', data => ... })
    my $frames = $docker->containers->logs($result->{Id}, tail => 100);
    my $text = join '', map { $_->{data} } @$frames;

    # Attach one-way: replays the same frames and returns (stream => 0 by
    # default -- stream => 1 on a stopped container never returns). On Podman,
    # attaching to a container that has ALREADY EXITED destroys its exit
    # status; use logs() for that case, see attach()
    my $attached = $docker->containers->attach($result->{Id});

    # Copy a file out, and a tar archive in (what docker cp is built on)
    my $tar = $docker->containers->get_archive($result->{Id},
        path => '/etc/hostname');
    $docker->containers->put_archive($result->{Id}, $tar, path => '/tmp');

=head1 DESCRIPTION

This module provides methods for managing Docker containers including creation,
lifecycle operations (start, stop, restart), inspection, logs, and more.

C<list> and C<inspect> return generated L<API::Docker::Type> objects carrying
the convenience methods of L<API::Docker::Role::Entity::Container>, so
C<< $container->start >> and C<< $container->logs >> work on either. Which
class each returns, and where the two disagree, is below.

Accessed via C<< $docker->containers >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->containers->using(read_timeout => 5) >>.

=head2 The two container shapes

The daemon describes a container two ways and the swagger has two
definitions for it, so this class returns two classes:

=over

=item * L</list> returns L<API::Docker::Type::ContainerSummary> objects --
one per entry of C<GET /containers/json>.

=item * L</inspect> returns an L<API::Docker::Type::ContainerInspectResponse>
-- the body of C<GET /containers/{id}/json>.

=back

They overlap but do not line up, and the field names are the swagger's own
spelling in snake_case (C<Id> is C<< ->id >>, C<SizeRootFs> is
C<< ->size_root_fs >>). The differences worth knowing before reading a value
off the wrong one:

=over

=item * C<< ->image >> is the name the container was created from on a
summary (C<nginx:latest>) and the resolved C<sha256:> digest on an inspect.
A summary reports that digest separately as C<< ->image_id >>; an inspect
has no such field.

=item * C<< ->created >> is an integer Unix epoch on a summary and an
RFC 3339 string on an inspect. Same field name, two types -- C<Int> and
C<Str> in the model, which is the swagger's own answer, not a normalisation
this client applies.

=item * C<< ->state >> is the status string (C<running>, C<exited>) on a
summary and an L<API::Docker::Type::ContainerState> object on an inspect,
where that string is C<< ->state->status >> and the flags are
C<< ->state->running >>, C<< ->state->paused >>, C<< ->state->exit_code >>.
L<API::Docker::Role::Entity::Container/is_running> reads whichever it is
given. C<< ->status >> -- the human sentence, C<"Up 2 hours"> -- is on the
summary only.

=item * C<< ->command >> is the whole command as one string, on a summary
only. An inspect splits it into C<< ->path >> and C<< ->args >> and keeps
the original C<Cmd> ArrayRef under C<< ->config->cmd >>.

=item * C<< ->labels >> and C<< ->ports >> are top-level on a summary only.
An inspect carries the labels under C<< ->config->labels >> and the port
bindings under C<< ->network_settings->ports >>, which is a map of container
port to host bindings rather than the summary's ArrayRef of
L<API::Docker::Type::Port>.

=item * C<< ->names >> (an ArrayRef, each with a leading C</>) is the
summary's; C<< ->name >> (one string, also with the C</>) is the inspect's.

=item * C<< ->config >>, C<< ->restart_count >>, C<< ->driver >>,
C<< ->platform >>, C<< ->graph_driver >>, C<< ->exec_ids >> and the
C<*_path> fields come from an inspect only.

=item * C<< ->host_config >> and C<< ->network_settings >> exist on both and
are B<different classes>: the summary's are
L<API::Docker::Type::ContainerSummary::HostConfig> (C<NetworkMode> and
C<Annotations>, nothing else) and
L<API::Docker::Type::ContainerSummary::NetworkSettings> (C<Networks> alone),
against the full L<API::Docker::Type::HostConfig> and
L<API::Docker::Type::NetworkSettings> on an inspect.

=item * C<< ->size_rw >> and C<< ->size_root_fs >> are on both, but a
summary only carries them when C<< size => 1 >> was asked for.

=back

A field neither class knows -- a newer engine than the C<spec/v1.51.yaml>
this model was generated from -- is not dropped: it stays under the name it
arrived with in L<API::Docker::Role::Type/unknown_fields> and goes back out
unchanged.

A field whose B<value> disagrees with the swagger is kept the same way and
costs only itself. An engine answering C<State> with the bare status string
rather than the object the spec declares leaves C<< ->state >> C<undef> while
every other field of the inspect reads normally; the raw value is in
C<unknown_fields> under C<State>, and
L<API::Docker::Role::Type/rejected_fields> names it, so "not sent" and "sent
and not usable" are two different answers.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $containers = $containers->list(%opts);

List containers. Returns an ArrayRef of
L<API::Docker::Type::ContainerSummary> objects -- see L</"The two container
shapes"> for what a summary carries and L</inspect> does not.

Options:

=over

=item * C<all> - Show all containers (default shows just running)

=item * C<limit> - Limit results to N most recently created containers

=item * C<size> - Include size information

=item * C<filters> - HashRef of filter name to ArrayRef of string values, e.g.
C<< { status => ['running'], label => ['stage=build'] } >>. Shape-checked and
normalised by L<API::Docker::Role::Filters>

=back

=head2 create

    my $result = $containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
        Cmd   => ['/bin/sh'],
        Env   => ['FOO=bar'],
    );

Create a new container. Returns hashref with C<Id> and C<Warnings>.

The C<name> parameter is extracted and passed as query parameter. All other
parameters are Docker container configuration (see Docker API documentation).

Common config keys: C<Image>, C<Cmd>, C<Env>, C<ExposedPorts>, C<HostConfig>.

Boolean flags may be given as a Perl C<1>/C<0> or as a JSON boolean; either
goes out as a real JSON C<true>/C<false>, which the engine's body type-check
requires. This applies to the top-level flags (C<Tty>, C<OpenStdin>,
C<AttachStdin>, C<AttachStdout>, C<AttachStderr>, C<StdinOnce>,
C<NetworkDisabled>, C<ArgsEscaped>) and to the C<HostConfig> flags
(C<Privileged>, C<PublishAllPorts>, C<ReadonlyRootfs>, C<AutoRemove>, C<Init>,
C<OomKillDisable>).

=head2 inspect

    my $container = $containers->inspect($id);

Get detailed information about a container. Returns an
L<API::Docker::Type::ContainerInspectResponse> -- see L</"The two container
shapes">.

=head2 start

    $containers->start($id);

    say 'was already running' unless $containers->start($id);

Start a container. Returns 1 when the container was started and 0 when it was
already running: the engine answers a state change with 204 and a no-op with
B<304 Not Modified>, and both carry an empty body, so until now both came back
as C<undef>.

The no-op keeps the falsy value this method always returned -- 0 where it used
to be C<undef> -- so a caller that ignores the return or tests it for falseness
is unaffected; only a caller testing C<defined> sees a difference. A failure is
still a croak, never a 0.

=head2 stop

    $containers->stop($id, timeout => 10);

    say 'was already stopped' unless $containers->stop($id);

Stop a container. Returns 1 when the container was stopped and 0 when it was
already stopped -- the engine answers the no-op with B<304 Not Modified>. See
L</start> for what that 0 replaces.

Options:

=over

=item * C<timeout> - Seconds to wait before killing (default 10)

=item * C<signal> - Signal to send (default SIGTERM)

=back

=head2 restart

    $containers->restart($id, timeout => 10);

Restart a container. Optionally specify C<timeout> in seconds.

Reports 1/0 like L</start>, but a restart has no no-op state to report: the
engine restarts a stopped container as readily as a running one. Measured
against Podman 5.4.2 (API 1.41) it answers 204 in both cases, and the Docker
Engine API documents no 304 for this endpoint either, so 0 is not expected
here. The value is reported the same way rather than specially, so an engine
that does answer 304 is not silently read as a change.

=head2 kill

    $containers->kill($id, signal => 'SIGKILL');

    $containers->kill($id, signal => 'SIGUSR1');   # not necessarily a stop

Send a signal to a container. Default signal is C<SIGKILL>.

Returns nothing -- unlike L</start>, L</stop>, L</restart>, L</pause> and
L</unpause>, which report 1/0 through their shared C<_state_change> path.
Those methods have two outcomes worth telling apart: a change (204) and a
no-op (304, where the engine sends one). C<kill> has only one, because
C<_request> croaks on any C<< status >= 400 >>, so the B<409> a non-running
container gets back never reaches this method's C<return>. A boolean with a
single possible value is not worth adding.

More importantly, B<204 does not mean the container stopped.> Measured on
B<both> engines -- Docker 29.7.2 (API 1.55) and rootless Podman 5.4.2 (API
1.41), same machine, identical behavior: sending a signal the container traps
or ignores -- C<< signal => 'SIGUSR1' >> against a process with a handler
installed for it -- is delivered, the container keeps running, the handler's
output turns up in L</logs>, and the engine still answers 204 exactly as it
does for a signal that does end the process. A caller that needs to know
whether the container is still running after a C<kill> has to ask
L</inspect>; that is also why this returns nothing rather than a plain C<1>
-- a 1 here would claim a state change that a trapped signal never made.

B<A paused container is where the two engines part.> Both answer 204 to
C<< signal => 'SIGUSR1' >> against a paused container, and then:

=over

=item * B<Docker unpauses it as a side effect.> L</inspect> reports C<running>
straight afterwards and the handler has already run. A caller that paused the
container and means to unpause it later gets a croak instead: the following
L</unpause> answers B<500> C<Container E<lt>idE<gt> is not paused>

=item * B<Podman leaves it paused> and queues the signal. The state stays
C<paused>, the handler produces nothing until an explicit L</unpause>, and
that L</unpause> succeeds

=back

So C<kill> is a state change for a paused container on Docker and is not one
on Podman -- with the same 204 on both.

Killing a container that is not running -- stopped, exited or just created --
croaks B<409>; it does not return a falsy value. An unknown container ID
croaks B<404>. Neither is reachable through a return value, and no case
answers 304: moby's swagger for this endpoint (C<operationId: ContainerKill>)
documents only 204, 404, 409 and 500.

The B<text> of either is engine prose, so branch on
L<API::Docker::Error::HTTP/status> and not on the message. For one and the
same stopped container:

=over

=item * Docker -- C<cannot kill container: E<lt>nameE<gt>: container E<lt>idE<gt> is
not running>

=item * Podman -- C<can only kill running containers. E<lt>idE<gt> is in state
exited: container state improper>. C<container state improper> is Podman's
separate C<cause> field, reachable as C<< $err->data->{cause} >>, not a
phrase Docker uses anywhere

=back

The 404 differs too, and on Docker it differs I<per endpoint>: C<kill>
against a missing ID answers C<cannot kill container: E<lt>nameE<gt>: No such
container: E<lt>nameE<gt>> where L</inspect> answers the bare C<No such container:
E<lt>nameE<gt>>. Podman sends one sentence for both.

Options:

=over

=item * C<signal> - Signal to send (default C<SIGKILL>)

=back

=head2 remove

    $containers->remove($id, force => 1, volumes => 1);

Remove a container.

Options:

=over

=item * C<force> - Force removal (kill if running)

=item * C<volumes> - Remove associated volumes

=item * C<link> - Remove specified link

=back

=head2 logs

    my $frames = $containers->logs($id, tail => 100, timestamps => 1);

    # stdout and stderr, in the order the engine emitted them
    my $text = join '', map { $_->{data} } @$frames;

    # stderr only
    my @errors = grep { $_->{stream} eq 'stderr' } @$frames;

Get container logs. Returns an ArrayRef of frames, each a HashRef with
C<stream> and C<data>:

    [ { stream => 'stdout', data => "OUT\n" },
      { stream => 'stderr', data => "ERR\n" } ]

A container created without a TTY multiplexes stdout and stderr into a single
framed stream, and this method demultiplexes it -- without that, the 8-byte
frame headers end up in the caller's log text. A container created B<with> a
TTY writes to one pty and the engine sends no frame headers, so its whole
output arrives as a single frame with C<< stream => 'raw' >>: with a TTY there
is no stdout/stderr distinction left to report. C<stream> is always a plain
string, so C<< $_->{stream} eq 'stderr' >> is safe on any frame.

Framing is detected from the response bytes, because the engine's
C<Content-Type> cannot be trusted for it -- see
L<API::Docker::Role::HTTP/"Detecting a framed stream"> for the rule and its one
failure mode.

Options:

=over

=item * C<follow> - Keep the connection open and send new output as the
container writes it. Only usable with C<on_frame>; see below

=item * C<stdout> - Include stdout (default 1)

=item * C<stderr> - Include stderr (default 1)

=item * C<since> - Show logs since timestamp

=item * C<until> - Show logs before timestamp

=item * C<timestamps> - Include timestamps

=item * C<tail> - Number of lines from end (e.g., C<100> or C<all>)

=item * C<tty> - Set to 1 when the container was created with a TTY and its
output is binary, to skip demultiplexing. Not needed for text output. The
container's own setting is C<Config.Tty> from C<< $containers->inspect($id) >>.
With C<on_frame> it is a declaration rather than a hint; see below

=item * C<on_frame> - CodeRef called with each frame as it arrives, instead of
the ArrayRef being collected and returned; see below

=back

=head2 Following the log

C<< follow => 1 >> asks the daemon to keep sending as the container writes.
Pass C<on_frame> with it and the frames are handed over as they arrive:

    my $summary = $containers->logs($id,
        follow   => 1,
        tail     => 0,
        on_frame => sub {
            my ($frame, $stop) = @_;
            print $frame->{data};
            $stop->() if $frame->{data} =~ /listening on/;
        },
    );

    $summary;   # { delivered => 4, stopped => 1 }

With a callback the return value is that summary HashRef, not the frames:
C<delivered> is how many went to the callback, C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated --
a followed log is unbounded by construction, and the callback has been handed
every frame already. See
L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

B<Without a callback, C<< follow => 1 >> blocks> until the container exits or
the daemon closes the connection, because the whole response is read before
anything is parsed. Use it with C<on_frame> or not at all.

C<tty> means something stronger on this path. The buffered path decides
framing by walking the whole body (see
L<API::Docker::Role::HTTP/"Detecting a framed stream">), which is exactly what
a streamed one does not have; so with C<on_frame> the flag is a promise about
the container rather than a hint, and an undeclared stream that turns out not
to be framed croaks instead of being handed back raw. Read C<Config.Tty> from
C<< $containers->inspect($id) >> and pass it. The frame shape is the same
either way -- a TTY stream arrives as a series of C<< stream => 'raw' >>
frames rather than the single one the buffered path builds.

=head2 attach

    my $frames = $containers->attach($id);

    my $text = join '', map { $_->{data} } @$frames;

Attach to a container's streams and return everything they produced, as an
ArrayRef of frames in the same shape L</logs> returns:

    [ { stream => 'stdout', data => "OUT\n" },
      { stream => 'stderr', data => "ERR\n" } ]

A container created without a TTY multiplexes its output into one framed
stream, which this method demultiplexes; one created with a TTY arrives as a
single C<< stream => 'raw' >> frame. See L</logs> and
L<API::Docker::Role::HTTP/"Detecting a framed stream">.

B<The container must be running.> Attaching to one that has already exited
destroys its exit status on Podman, so this method checks first and croaks
rather than attaching -- read the output of a finished container with
L</logs>. Both halves of that are worth knowing before the call: see
L</"On Podman this destroys a stopped container's exit status"> and
L</"This method refuses a container that is not running">.

=head2 On Podman this destroys a stopped container's exit status

B<Attaching to a container that has already exited loses its exit code on
Podman, and nothing reports it.> Measured before and after a single attach
against one container that exited with 4, on Podman 5.4.2 (API 1.41) and
Docker 29.7.2 (API 1.55), same machine:

    PODMAN  before   inspect: exited 4    wait: { StatusCode => 4 }
    PODMAN  after    inspect: created 0   wait: { StatusCode => -1 }
    DOCKER  before   inspect: exited 4    wait: { StatusCode => 4 }
    DOCKER  after    inspect: exited 4    wait: { StatusCode => 4 }

Podman reverts the container to C<created>, resets C<ExitCode> to 0, and
answers a later L</wait> with the sentinel C<-1> inside a 200. The real value
is gone from the engine; there is nothing to read it back from. B<All three
variants do it> -- C<< stream => 1 >> with and without C<logs>, and the
C<< stream => 0, logs => 1 >> this method now sends by default, which is the
one that returns cleanly in milliseconds. It is the call that does it, not
the hang.

L</logs> does B<not> do it, and Docker does not do it at all. So on Podman
the sequence "attach to collect the output, then L</wait> for the exit code"
cannot work: read the output with L</logs> instead, or take the exit code
before attaching.

=head2 This method refuses a container that is not running

Because of the above, C<attach> asks L</inspect> whether the container is
running and B<croaks instead of attaching> when it is not:

    API::Docker::API::Containers->attach refused: container x is exited. ...

C<< require_running => 0 >> turns that off and attaches anyway; the check is
then not performed at all, so opting out costs no round trip either.

With the guard off, the hang this section exists to explain becomes reachable:
attaching to a container that has already exited never returns on rootless
Podman (measured 5.4.2, still true on 5.8.4, API 1.44). A bound on the
resource class is how to survive that call instead of blocking on it forever:

    $docker->containers->using(read_timeout => 2)
      ->attach($id, require_running => 0);

See L<API::Docker::Role::Using> and
L<API::Docker::Role::HTTP/"Bounding a request that never ends">.

B<What the check does not do is close the race.> It is a pre-flight question,
and the container can stop between the answer and the attach arriving -- in
which case the exit status is destroyed exactly as it would have been without
the check. The engine offers no attach-if-running, so this cannot be fixed
from a client. What makes the check worth its round trip is that the window is
one round trip wide rather than unbounded, and that the condition it tests is
precisely the condition that does the damage. Measured, one container per row,
each exiting with status 4:

    attach to an ALREADY-EXITED container       Podman: status destroyed
    attach while RUNNING, exits under the call  Podman: status intact (4)
    either of those                             Docker: status intact (4)

A container that is still running when the attach is sent therefore stays
safe even when it exits a millisecond later. The damage needs the container to
be stopped B<already>, which is the common case and the one the check catches:
a caller reaching for a container it knows has finished.

Refusing costs a caller nothing that C<attach> could have given them, on
either engine. Against a container that is not running there is no combination
that is both safe and useful: on Podman every variant destroys the exit
status, C<< stream => 1 >> hangs forever on B<both> engines (measured: Docker
was still open when a 10 s probe gave up), and Docker's C<< stream => 0 >>
replay returns the same frames L</logs> returns, with none of the hazard and
with C<tail> and C<since> on top.

The check is engine-independent although the data loss is Podman's alone.
Telling the engines apart would cost a round trip of its own, it would leave
the both-engine C<< stream => 1 >> hang in place, and it would make the safe
call on Docker a call this distribution recommends against anywhere else.

B<This is a behavior change.> Up to and including the previous release the
call went straight to the engine.

=head2 This is the one-way attach

The engine has two attach protocols behind one path. Sent with
C<Upgrade: tcp> and C<Connection: Upgrade>, C<< POST /containers/{id}/attach >>
answers B<101 Switching Protocols> and hands over a bidirectional connection:
that is what C<docker attach> uses, and it is what lets a caller type into the
container's stdin. Sent B<without> those headers -- which is what this method
does -- the engine answers B<200> and streams the container's output one way,
in exactly the frames L</logs> returns.

This method implements the second one only, because the transport here buffers
a whole response before returning it (see
L<API::Docker::Role::HTTP/"What the transport does not do">). Two consequences
a caller has to plan around:

=over

=item * B<You cannot write to the container.> C<< stdin => 1 >> is passed to
the engine, but this client sends no bytes after the request headers and then
reads until the daemon closes, so there is no moment at which input could be
supplied. Use L<API::Docker::API::Exec> to run something interactive-shaped,
or wait for the upgraded variant

=item * B<Without a callback it returns when the stream ends, not before.>
With C<< stream => 1 >>, attaching to a container that keeps running blocks
until it exits or the daemon closes the connection -- and on a container that
is B<not> running it never returns at all, see
L</"The defaults follow the engine"> below. Pass C<on_frame> to read the
stream as it arrives and stop where you like, exactly as L</logs> does under
L</"Following the log">; the return value is then the summary HashRef
C<< { delivered => N, stopped => 0|1 } >> rather than the frames, and C<tty>
becomes a declaration the transport takes at its word -- an undeclared
unframed stream croaks. For a running container that need not be attached to,
L</logs> with C<tail> reads the same output and returns immediately

=back

C</containers/{id}/attach/ws>, the WebSocket variant, is not implemented
either.

=head2 The defaults follow the engine

C<stream> defaults to B<0> -- the engine's own default -- and C<logs> to
B<1>, which is the one flag that keeps the call useful without it. So
C<< $containers->attach($id) >> B<replays> what the container has written and
returns.

B<This is a change.> Up to and including the previous release C<stream>
defaulted to 1, so the same call opened an open-ended subscription; a caller
who wants the live stream now has to ask for it with C<< stream => 1 >>.

The reason is that the subscription has exactly one terminator: the container
ending. C<stream> means I<stream attached streams from the time the request
was made onwards>, so on a container that has B<already exited> that
terminator is in the past and will not happen again. attach also hijacks the
connection -- the response carries no C<Content-Length> and no chunked
terminator -- so HTTP framing cannot signal the end either. The transport
reads until EOF, there is no EOF, and the call hangs. C<on_frame> does not
help: nothing will ever call C<< $stop->() >>.

Measured on Podman 5.4.2 (API 1.41), all four against one and the same
container:

=over

=item * C<?logs=1&stdout=1&stderr=1&stream=0>, exited container -- 200, the
frames, connection closed after 13 ms

=item * C<?logs=1&stdout=1&stderr=1&stream=1>, exited container -- 200, the
same frames, then hangs

=item * the same with C<Upgrade: tcp> -- 101 UPGRADED, the same frames, still
hangs

=item * C<?stream=1> while the container is still B<running> and exits three
seconds later -- closes cleanly after 3 s

=back

B<Docker does exactly the same, and that is measured now too.> Against Docker
29.7.2 (API 1.55): C<?logs=1&stdout=1&stderr=1&stream=1> on an exited
container was still open when a 10 s probe gave up, and
C<?logs=1&stdout=1&stderr=1&stream=0> answered 200 with byte-identical frames
and closed in half a millisecond. So the hang is not a Podman quirk to be
worked around -- it is what both engines do with a subscription whose only
terminator is already in the past, on an endpoint whose reference promises a
close in neither direction. It is unspecified behavior on both, which is the
case for the C<< stream => 0 >> default rather than an argument against it.

One more measured difference: Podman refuses C<< stream => 0 >> together with
C<< logs => 0 >> outright, with B<400> C<at least one of Logs or Stream must
be set>, rather than answering an empty 200.

Options:

=over

=item * C<stream> - Subscribe to what the container writes from the time of
the request onwards. Default B<0>, which is the engine's own default.
C<< stream => 1 >> on a container that is not running never returns; see
L</"The defaults follow the engine">

=item * C<logs> - Replay what the container has already written. Default
B<1>, so the call returns something without subscribing; combined with
C<< stream => 1 >> the replay comes first and then transitions seamlessly
into the live output. C<< logs => 0 >> without C<< stream => 1 >> is the
combination the engine refuses (400 on Podman)

=item * C<stdout> - Attach stdout. Default 1 (engine default: false)

=item * C<stderr> - Attach stderr. Default 1 (engine default: false)

=item * C<stdin> - Attach stdin. Sent as asked, but nothing can be written to
it here; see above

=item * C<tty> - Set to 1 when the container was created with a TTY and its
output is binary, to skip demultiplexing. Same meaning as in L</logs>, and
with C<on_frame> the same promise

=item * C<on_frame> - CodeRef called with each frame as it arrives, instead of
the ArrayRef being collected and returned. Same contract as in L</logs>

=item * C<require_running> - Ask L</inspect> whether the container is running
first, and croak rather than attach when it is not. Default B<1>. Set to 0 to
attach to a stopped container anyway, which also skips the round trip; see
L</"This method refuses a container that is not running"> for what the check
does and does not guarantee

=back

=head2 top

    my $processes = $containers->top($id, ps_args => 'aux');

List running processes in a container. Returns hashref with C<Titles> and C<Processes> arrays.

Options:

=over

=item * C<ps_args> - Arguments passed to C<ps> inside the container, e.g.
C<'aux'>. Omitted, the engine uses its own default

=back

=head2 stats

    my $stats = $containers->stats($id);

Get container resource usage statistics (CPU, memory, network, I/O). With no
options this is the one-shot call it always was: a single reading, returned as
a HashRef.

For a container that is B<not running> the two engines answer differently and
neither says so in the status line -- on Podman this method croaks, on Docker
it returns zeros that look like a reading. See
L</"A container that is not running: a croak on Podman, zeros on Docker">
before calling it on a container that may have stopped.

=head2 Following the stats

C<< stream => 1 >> asks the engine for a reading per sampling cycle for as long
as the container runs. Pass C<on_event> with it and the readings are handed
over as they arrive:

    my $summary = $containers->stats($id,
        stream   => 1,
        on_event => sub {
            my ($stats, $stop) = @_;
            printf "%.1f MB\n", $stats->{memory_stats}{usage} / 1024 ** 2;
            $stop->() if ++$seen >= 5;
        },
    );

    $summary;   # { delivered => 5, stopped => 1 }

With a callback the return value is that summary HashRef, not the readings:
C<delivered> is how many went to the callback, C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated.
See L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

B<Without a callback, C<< stream => 1 >> blocks> until the container stops or
the daemon closes the connection: the whole response is read before anything
is parsed. It then returns an ArrayRef of readings rather than the single
HashRef the one-shot call returns, which is the other reason to pass a
callback instead.

Unlike L<API::Docker::API::System/events>, this does not turn the stream's
error check off. C</events> is a feed of engine records, where an
C<errorDetail> object would still be data; a stats stream is one container's
readings, and the transport's default is to croak on a failure reported inside
a 200 body (L<API::Docker::Role::HTTP/"Failure inside a 200 response">).

The default is kept on a measurement rather than on that analogy. Against
Podman 5.4.2 (API 1.41) every object a running container's stream carries is
a complete reading -- C<read>, C<cpu_stats>, C<memory_stats>, C<networks> and
the rest -- and killing the container and then removing it while the stream
was open ended the stream on a whole reading, with nothing appended after it.
No C<errorDetail> was sent in either case, and the Engine API reference names
that key for C</build>, C</images/create> and C</images/{name}/push> alone.
So the check has no legitimate reading here it could turn into a croak, and
that -- not an unexamined default -- is why it stays on.

Options:

=over

=item * C<stream> - Ask for a reading per sampling cycle instead of one.
Defaults off and is always sent, so a call with no options is the single
reading it has always been

=item * C<on_event> - CodeRef called with each reading as it arrives, instead
of them being collected and returned; see above

=back

=head2 A container that is not running: a croak on Podman, zeros on Docker

Neither engine answers this with an HTTP error, and they agree on nothing
else. Measured on Podman 5.4.2 (API 1.41) and Docker 29.7.2 (API 1.55), same
machine, one container that had exited.

B<Podman sends an error object inside the 200> -- chunked, for the one-shot
call and for C<< stream => 1 >> alike:

    { cause    => 'container is stopped',
      message  => 'container is stopped',
      response => 500 }

B<This method now croaks on it>, with an L<API::Docker::Error::HTTP> carrying
C<< ->status == 500 >> -- the code Podman named in C<response> -- and the
object itself as C<< ->data >>, so C<< $err->data->{cause} >> stays readable.
That is a B<change>: up to and including the previous release the one-shot
call returned this HashRef where a reading was expected, and an C<on_event>
callback was handed it as though it were one. The check runs on the buffered
return value and in front of the callback alike, and only on that exact
shape -- a HashRef inside a 2xx carrying all three of C<cause>, C<message>
and C<response> lower-cased, with C<response> reading as an integer >= 400.
Nothing else in this distribution, in its fixtures, or in a sweep of fifteen
read endpoints per engine carries even one of those keys lower-cased at the
top level. The rule is deliberately B<not> case-insensitive: a I<successful>
L</wait> answers with a top-level C<Error> key, and a looser rule would
report every one of those as a failure.

B<Docker sends a structurally valid reading with everything zeroed> -- 200,
about 825 bytes, no error anywhere in it:

    { id => '...', name => '/...', os_type => 'linux',
      read      => '0001-01-01T00:00:00Z',
      cpu_stats => { cpu_usage => { total_usage => 0, ... }, ... },
      memory_stats => {}, pids_stats => {}, num_procs => 0, ... }

So the advice this section used to give -- test for C<read> or C<cpu_stats>
before using what comes back -- is B<wrong on Docker>: both keys are present,
both look plausible, the test passes, and the caller uses zeros as though
they were a measurement. The markers in that body are Go's zero time in
C<read> (C<0001-01-01T00:00:00Z>) and an empty C<memory_stats>, and those are
Docker's shape rather than anybody's contract.

C<num_procs> is B<not> one of them, contrary to what this section said before
it was measured: a one-shot reading taken from a container that was genuinely
B<running> on Docker 29.7.2 carries C<< num_procs => 0 >> as well. It is zero
on that engine either way and separates nothing.

The engine-independent question is not about the reading at all: ask
L</inspect> whether the container is running. Treat the zero timestamp as a
cheap Docker-specific second opinion, not as the test.

=head2 C<< stream => 1 >> on a container that is not running

The same call in follow mode fails in B<opposite> directions on the two
engines, and the standing advice for a streaming endpoint -- bound the
window -- does not help, because there is no window to bound:

=over

=item * B<Podman> sends the one error object above and closes at once. Without
a callback that arrives as a one-element ArrayRef; either way this method
croaks it

=item * B<Docker> streams one zero-filled reading B<per second, forever>.
Measured: 5 objects in a 5 s probe, 12 in a 12 s probe, the connection never
closed by the engine. No container exit will ever end it -- the container had
already exited when the call was made

=back

C<< stream => 1 >> without a callback therefore never returns on Docker for a
container that is not running. C<on_event> plus a C<< $stop->() >> is the
only way out, and there the callback has to decide for itself that a reading
is not one: that stream carries nothing to croak on.

=head2 On Docker the stream does not end when the container does

Worse, and measured since: the container does B<not> have to be stopped when
the call is made. A C<< stream => 1 >> opened on a container that was
genuinely B<running> on Docker 29.7.2 does not end when that container exits.
It degrades. One 20 s probe against a container that exited after 3 s:

    3 real readings, then 13 zero-filled ones, connection still open at 20 s

Podman ends the same stream on the container's exit -- 5.0 s for the same
probe, the last object a whole reading.

So on Docker C<< stream => 1 >> has B<no> terminator tied to the container at
all, and the readings turn to zeros without anything in the stream saying so.
A caller that follows a container's stats until it stops is asking for
something this endpoint does not offer on that engine: give C<on_event> its
own stopping condition -- a reading count, a deadline, or the Go zero time in
C<read> -- and do not wait for the stream to end on its own.

B<C<read_timeout> does not bound this.> It is an idle timeout -- silence since
the last byte -- and this stream is never silent: it keeps producing a
zero-filled reading once a second, indefinitely, so the clock that C<read_timeout>
measures never runs out. C<read_timeout> bounds a daemon that goes quiet; a
Docker stats stream after container exit does the opposite -- it keeps talking,
just not truthfully. C<on_event> still has to notice the Go zero time in
C<read> and call C<< $stop->() >> itself; do not rely on C<read_timeout> to end
this case.

=head2 Why this is documented and not guarded

L</attach> refuses a container that is not running (see
L</"This method refuses a container that is not running">). This method does
B<not>, and the difference is deliberate rather than an inconsistency.

A pre-flight L</inspect> can only answer I<is it running now>. For L</attach>
that is the whole question: the damage needs the container to be stopped
already, so the check leaves a window one round trip wide. For this method it
is the wrong question -- the hazard is the container stopping at B<any> point
in a stream that may run for hours, which the measurement above is exactly a
case of. A guard here would have returned "running, go ahead" and the caller
would have hung anyway. Its blind spot is not a round trip, it is the entire
stream.

The second difference is that nothing here is destroyed. This is a read: after
a hang or a pocketful of zeros, L</inspect> still reports the truth and the
exit status is still there. That is precisely what L</attach> takes away -- a
caller cannot check afterwards, because checking afterwards is the thing that
stops working. A guard is worth an unclosable race when the alternative is
unrecoverable, and is not worth it when the caller can simply ask again.

What can be caught for free already is: Podman reports its refusal in the body
and this method croaks on it, with no extra request and no race.

=head2 changes

    for my $change (@{ $containers->changes($id) }) {
        say $KIND[ $change->{Kind} ], ' ', $change->{Path};
    }

Report which paths in the container's filesystem differ from the image it was
created from -- the endpoint behind C<docker diff>. Returns an ArrayRef of
HashRefs, each with C<Path> and C<Kind>:

    [ { Path => '/etc/hostname', Kind => 0 },
      { Path => '/tmp/new',      Kind => 1 },
      { Path => '/etc/gone',     Kind => 2 } ]

C<Kind> is an integer, not a word, and the engine documents no names for the
three values:

=over

=item * C<0> - B<modified>. The path exists in both and its contents or
metadata changed

=item * C<1> - B<added>. The path exists only in the container

=item * C<2> - B<deleted>. The path existed in the image and is gone

=back

A container with nothing changed comes back as an empty ArrayRef; the engine
answers that case with a JSON C<null> rather than an empty list.

Measured against Podman 5.4.2 (API 1.41): the endpoint is served, but an
unknown container is answered with B<500> and
C<< {"cause":"layer not known","message":"<id> not found: layer not known"} >>
rather than the 404 every other container endpoint gives -- so a caller
distinguishing "no such container" from a real failure cannot do it on the
status code alone on that engine.

=head2 export

    use Path::Tiny;
    path('container.tar')->spew_raw($containers->export($id));

Export the container's whole filesystem as a tar archive -- the endpoint
behind C<docker export>. Returns the raw archive bytes, never decoded and
never modified.

The archive is buffered whole in memory, so this costs the size of the
container's filesystem in RAM. There is no streaming variant here.

Unlike L<API::Docker::API::Images/get>, the result is a plain filesystem tar:
no C<manifest.json>, no layers, no image metadata. L<API::Docker::API::Images/load>
will not take it back -- importing a flat filesystem is
C<< POST /images/create?fromSrc=- >>, which this distribution does not expose.

=head2 resize

    $containers->resize($id, h => 40, w => 120);

Resize the TTY of a container, so a program inside it sees the new terminal
size. Form-identical to L<API::Docker::API::Exec/resize>, which resizes the
TTY of an exec instance instead.

Only meaningful for a container created with C<< Tty => 1 >>; the engine
rejects the call otherwise.

Options:

=over

=item * C<h> - New height in character rows

=item * C<w> - New width in character columns

=back

=head2 wait

    my $result = $containers->wait($id);
    my $code   = $result->{StatusCode};

    $containers->wait($id, condition => 'not-running');

Block until the container reaches a condition, then return B<a HashRef> --
not the exit code. C<StatusCode> is the exit status of the container's main
process, and it is the one key both engines always send:

    { StatusCode => 4 }                    # Docker 29.7.2 (API 1.55)
    { StatusCode => 4, Error => undef }    # Podman 5.4.2 (API 1.41)

B<The C<Error> key diverges, and C<exists> is the wrong test for it.>
Measured on successful waits on both engines: Docker B<omits> the key
entirely, Podman sends C<"Error": null> on every wait, which decodes to
C<undef>. So C<< exists $result->{Error} >> is false on Docker and true on
Podman for one and the same outcome, while C<< defined $result->{Error} >> is
false on both. Ask C<defined>, never C<exists>, and take C<StatusCode> as the
answer.

A B<non-null> C<Error> was not produced on either engine by any probe behind
this documentation. The Engine API reference documents it as an object
carrying C<Message>; that shape is B<documented but not measured here>, which
is not the same as unreachable -- do not write code that assumes it cannot
appear, and do not trust its shape without checking.

The call blocks in the client for as long as the engine takes to answer: this
endpoint answers only once the condition is met, and the whole response is
read before anything is parsed. There is no timeout, on this method or in the
transport.

Measured on both engines:

=over

=item * A container that has B<already exited> answers immediately with its
real exit status -- with no condition and with C<not-running> alike

=item * A container that was B<created and never started> answers immediately
with an invented one: Docker C<< StatusCode => 0 >>, Podman
C<< StatusCode => -1 >>. There is no exit status to report and the two
engines make up different ones, so a C<0> from this call is not proof that
anything ran

=item * C<< condition => 'next-exit' >> and C<< condition => 'removed' >>
against an exited container B<block> on both engines: the awaited event is in
the future and may never happen

=item * An unrecognised condition croaks B<400> on both (Docker C<invalid
condition: "...">, Podman C<failed to parse query parameter 'condition' ...>),
and an unknown container ID croaks B<404>

=back

Podman also answers C<< StatusCode => -1 >> for a container whose exit status
L</attach> has destroyed -- see
L</"On Podman this destroys a stopped container's exit status">. The value is
that engine's sentinel for "no status", not an exit code.

This endpoint is also the reason the error check on L</stats> matches
C<cause>, C<message> and C<response> case-sensitively: a I<successful> wait
is a 2xx body with a top-level C<Error> key in it, and a rule matching
C<error> case-insensitively would turn every one of them into a failure.

Options:

=over

=item * C<condition> - What to wait for: C<not-running> (the engine's own
default), C<next-exit> or C<removed>. Sent only when given

=back

=head2 pause

    $containers->pause($id);

Pause all processes in a container.

Reports 1/0 like L</start>, but pausing an already-paused container is an
error rather than a 304: measured against Podman 5.4.2 (API 1.41) it answers
C<500> with C<< "..." is already paused: container state improper >>, which
croaks. The Docker Engine API documents no 304 for this endpoint either. So
this method returns 1 or croaks in practice.

=head2 unpause

    $containers->unpause($id);

Unpause all processes in a container. Reports 1/0 like L</start>; as with
L</pause>, the no-op is an error and not a 304 -- Podman 5.4.2 answers
unpausing a running container with C<500>.

=head2 rename

    $containers->rename($id, 'new-name');

Rename a container.

=head2 update

    $containers->update($id, Memory => 314572800);

Update container resource limits and configuration.

The boolean flags (C<Init>, C<OomKillDisable>) may be given as a Perl C<1>/C<0>
or as a JSON boolean; either goes out as a real JSON C<true>/C<false>, which
the engine's body type-check requires.

=head2 get_archive

    use Path::Tiny;
    my $tar = $containers->get_archive($id, path => '/etc/hostname');
    path('hostname.tar')->spew_raw($tar);

    # and what the path was, without a second request
    my %stat;
    my $tar = $containers->get_archive($id, path => '/var/log', stat => \%stat);
    say $stat{name};

Read a path out of a container as a tar archive -- the outbound half of
C<docker cp>. Returns the raw archive bytes, never decoded and never modified.

A file comes back as a one-member archive named after its basename; a
directory comes back as the directory and everything under it, with paths
relative to its parent. The whole archive is buffered in memory.

Options:

=over

=item * C<path> - Path inside the container to read. Required

=item * C<stat> - HashRef the C<X-Docker-Container-Path-Stat> header is
decoded into. The engine sends it on this response as well as on the HEAD
one, so asking for it here saves the extra round trip L</stat_archive> would
cost. Emptied when the engine sent no such header. See L</stat_archive> for
the keys

=back

=head2 put_archive

    use Path::Tiny;
    $containers->put_archive($id, path('payload.tar')->slurp_raw,
        path => '/opt/app');

Write a tar archive into a path inside the container -- the inbound half of
C<docker cp>. The archive is the request body; pass it as raw bytes or as a
scalar reference to them, the way L<API::Docker::API::Images/load> takes its
archive. Returns nothing: the engine answers a success with an empty body.

C<path> must name a B<directory that already exists> in the container; the
archive's members are unpacked into it. Writing a single file means putting
that file in a one-member archive and naming its parent directory as C<path> --
there is no "write these bytes to this filename" form of this endpoint.

The archive is sent as one buffered request body, so this costs its full size
in RAM.

Options:

=over

=item * C<path> - Directory inside the container to unpack into. Required

=item * C<noOverwriteDirNonDir> - Refuse the request rather than replace an
existing directory with a non-directory, or the other way round. Without it
the engine replaces either with the other

=item * C<copyUIDGID> - Keep the UID and GID recorded in the archive instead
of mapping the members to the container user

=back

=head2 stat_archive

    my $stat = $containers->stat_archive($id, path => '/etc/hostname');

    say $stat->{name};                        # hostname
    say $stat->{size};                        # 13
    printf "%04o\n", $stat->{mode} & 0777;    # 0644

Stat a path inside a container without transferring it -- C<HEAD> on the same
endpoint L</get_archive> uses. Returns a HashRef, or C<undef> when the engine
answered without the header. A path that does not exist is a croak from the
transport's status handling, not an C<undef>.

The response has no body at all: the answer is the
C<X-Docker-Container-Path-Stat> header, base64-encoded JSON, which this method
decodes. Its keys are the engine's, passed through as they arrive:

=over

=item * C<name> - The path's basename. For a symlink the two engines
disagree: Docker reports the requested path's own basename, Podman the
resolved target's

=item * C<size> - Size in bytes

=item * C<mode> - Go's C<os.FileMode> bits, B<not> a POSIX mode word, on both
engines. The permission bits are the low nine (C<< $stat->{mode} & 0777 >>);
the type bits above them are Go's own numbering, so a directory's C<mode> is
C<os.ModeDir> (C<< 1<<31 >>) plus the permission bits -- C<2147484141> for a
C<0755> directory -- rather than POSIX's C<S_IFDIR>, which for the same
directory would give C<16877>

=item * C<mtime> - Modification time, RFC 3339

=item * C<linkTarget> - The symlink target. Docker sends the literal,
unresolved link content, and leaves this empty for anything that is not a
symlink exactly as the Engine API reference documents; Podman sends the
fully I<resolved> path instead, and was measured populating it even for a
plain regular file, where Docker leaves it empty

=item * C<isDir> - Boolean, true when the path is a directory. B<Podman
only> -- Docker was measured never sending this key, not even for a
directory, so it is not part of the Docker Engine API's own answer

=back

This shape is confirmed against Podman, not assumed: measured against the
rootless socket, C<stat_archive> on Podman returns exactly these six keys.
For a symlink such as F<hnlink> pointing at F</etc/hostname>, Docker reports
C<name> as C<hnlink> (the link's own basename) and C<linkTarget> as
C</etc/hostname> (the raw, unresolved content); Podman reports C<name> as
C<hostname> (the resolved target's basename) and the fully resolved path in
C<linkTarget>. The route itself was measured the same way on Podman: an
unknown container answers 404, and that 404 announces a C<Content-Length>
while sending no body -- which is why L<API::Docker::Role::HTTP/head> never
reads one.

Options:

=over

=item * C<path> - Path inside the container to stat. Required

=back

=head2 prune

    my $result = $containers->prune(filters => { until => ['24h'] });

Delete stopped containers. Returns hashref with C<ContainersDeleted> and C<SpaceReclaimed>.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<until> and C<label> here. Shape-checked and normalised by
L<API::Docker::Role::Filters>

=back

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Role::Entity::Container> - the convenience methods
the returned objects carry

=item * L<API::Docker::Type::ContainerSummary> - what L</list> returns

=item * L<API::Docker::Type::ContainerInspectResponse> - what L</inspect>
returns

=item * L<API::Docker::API::Exec> - Execute commands in containers

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
