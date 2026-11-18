package API::Docker::API::Images;
# ABSTRACT: Docker Engine Images API
our $VERSION = '0.006';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::RegistryAuth',
  'API::Docker::Role::Using';
use API::Docker::Role::Entity::Image;
use API::Docker::Type::ImageInspect;
use API::Docker::Type::ImageSummary;
use Carp qw( croak );
use JSON::MaybeXS qw( encode_json );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


# The class is the caller's argument rather than a constant of this module:
# `list` and `inspect` are two definitions in the swagger and therefore two
# generated classes. Both carry the same convenience methods, composed by
# API::Docker::Role::Entity::Image -- see "The two image shapes".
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

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{all}     = $opts{all} ? 1 : 0     if defined $opts{all};
  $params{digests} = $opts{digests} ? 1 : 0 if defined $opts{digests};
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  my $result = $self->client->get('/images/json',
    params => \%params,
    %{ $self->_request_options },
  );
  return $self->_wrap_list('API::Docker::Type::ImageSummary', $result // []);
}


sub build {
  my ($self, %opts) = @_;
  my $context = delete $opts{context};
  croak "Build context required (tar archive as scalar ref or raw bytes)" unless defined $context;

  my %params;
  $params{dockerfile} = $opts{dockerfile} if defined $opts{dockerfile};
  $params{t}          = $opts{t}          if defined $opts{t};
  $params{q}          = $opts{q} ? 1 : 0  if defined $opts{q};
  $params{nocache}    = $opts{nocache} ? 1 : 0 if defined $opts{nocache};
  $params{pull}       = $opts{pull}       if defined $opts{pull};
  $params{rm}         = defined $opts{rm} ? ($opts{rm} ? 1 : 0) : 1;
  $params{forcerm}    = $opts{forcerm} ? 1 : 0 if defined $opts{forcerm};
  $params{memory}     = $opts{memory}     if defined $opts{memory};
  $params{memswap}    = $opts{memswap}    if defined $opts{memswap};
  $params{cpushares}  = $opts{cpushares}  if defined $opts{cpushares};
  $params{cpusetcpus} = $opts{cpusetcpus} if defined $opts{cpusetcpus};
  $params{cpuperiod}  = $opts{cpuperiod}  if defined $opts{cpuperiod};
  $params{cpuquota}   = $opts{cpuquota}   if defined $opts{cpuquota};
  $params{shmsize}    = $opts{shmsize}    if defined $opts{shmsize};
  $params{networkmode} = $opts{networkmode} if defined $opts{networkmode};
  $params{platform}   = $opts{platform}   if defined $opts{platform};
  $params{target}     = $opts{target}     if defined $opts{target};

  $params{buildargs} = encode_json($opts{buildargs}) if $opts{buildargs};
  $params{labels}    = encode_json($opts{labels})    if $opts{labels};

  my $raw = ref $context eq 'SCALAR' ? $$context : $context;

  # A build's registry credentials ride in X-Registry-Config, not
  # X-Registry-Auth: the map lets `FROM private.registry/...` authenticate,
  # and a build may draw base images from several registries at once. Sent
  # only when given -- an anonymous build needs no header.
  my %headers;
  $headers{'X-Registry-Config'} =
    $self->_registry_config_header($opts{registry_config})
    if defined $opts{registry_config};

  # exists, not truth: an unset callback is a caller bug, and falling back to
  # the buffered path for it would hand a long build back as silence.
  return $self->client->_request('POST', '/build',
    raw_body     => $raw,
    content_type => 'application/x-tar',
    params       => \%params,
    %headers ? ( headers => \%headers ) : (),
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $opts{on_event} ) : ( ndjson => 1 ),
  );
}


# The tag query parameter is not a default to hand out unconditionally: the
# engine appends it to whatever reference `fromImage` already carries. Docker
# lets tag take precedence and silently rewrites `nginx:1.25` to `nginx:latest`
# (a wrong image, reported as success); Podman concatenates to
# `nginx:1.25:latest` and answers 500 `invalid reference format`. A digest
# reference breaks the same way on both. So `tag` is defaulted only when the
# reference carries neither -- a `:tag` in the segment after the last `/`, or an
# `@digest` anywhere. The colon in a registry `host:port/` is before that
# segment, so it is not mistaken for a tag.
sub _reference_has_tag_or_digest {
  my ($self, $ref) = @_;
  return 1 if $ref =~ /\@/;
  my ($last_segment) = $ref =~ m{([^/]*)\z};
  return $last_segment =~ /:/ ? 1 : 0;
}

# Only when credentials were given: an anonymous pull needs no header, and the
# engine reads X-Registry-Auth off /images/create only to reach a private
# registry. This is the plugins/distribution policy, not push's always-send --
# push must send even the anonymous {} because the engine rejects a push with
# no header at all.
sub _auth_headers {
  my ($self, $opts) = @_;
  return () unless defined $opts->{auth};
  return (headers => { 'X-Registry-Auth' => $self->_registry_auth_header($opts->{auth}) });
}

sub pull {
  my ($self, %opts) = @_;
  croak "fromImage required" unless $opts{fromImage};
  my %params;
  $params{fromImage} = $opts{fromImage};
  if (defined $opts{tag}) {
    $params{tag} = $opts{tag};
  }
  elsif (!$self->_reference_has_tag_or_digest($opts{fromImage})) {
    $params{tag} = 'latest';
  }
  return $self->client->post('/images/create', undef,
    params => \%params,
    $self->_auth_headers(\%opts),
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $opts{on_event} ) : ( ndjson => 1 ),
  );
}


sub inspect {
  my ($self, $name) = @_;
  croak "Image name required" unless $name;
  my $result = $self->client->get("/images/$name/json",
    %{ $self->_request_options },
  );
  return $self->_wrap('API::Docker::Type::ImageInspect', $result);
}


sub history {
  my ($self, $name) = @_;
  croak "Image name required" unless $name;
  return $self->client->get("/images/$name/history",
    %{ $self->_request_options },
  );
}


sub push {
  my ($self, $name, %opts) = @_;
  croak "Image name required" unless $name;
  my %params;
  $params{tag} = $opts{tag} if defined $opts{tag};

  my $auth_header = $self->_registry_auth_header($opts{auth});

  return $self->client->post(
    "/images/$name/push",
    undef,
    params  => \%params,
    headers => { 'X-Registry-Auth' => $auth_header },
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $opts{on_event} ) : ( ndjson => 1 ),
  );
}


sub tag {
  my ($self, $name, %opts) = @_;
  croak "Image name required" unless $name;
  my %params;
  $params{repo} = $opts{repo} if defined $opts{repo};
  $params{tag}  = $opts{tag}  if defined $opts{tag};
  return $self->client->post("/images/$name/tag", undef,
    params => \%params,
    %{ $self->_request_options },
  );
}


sub remove {
  my ($self, $name, %opts) = @_;
  croak "Image name required" unless $name;
  my %params;
  $params{force}   = $opts{force} ? 1 : 0   if defined $opts{force};
  $params{noprune} = $opts{noprune} ? 1 : 0 if defined $opts{noprune};
  return $self->client->delete_request("/images/$name",
    params => \%params,
    %{ $self->_request_options },
  );
}


sub search {
  my ($self, $term, %opts) = @_;
  croak "Search term required" unless $term;
  my %params;
  $params{term}    = $term;
  $params{limit}   = $opts{limit}   if defined $opts{limit};
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->client->get('/images/search',
    params => \%params,
    %{ $self->_request_options },
  );
}


sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->client->post('/images/prune', undef,
    params => \%params,
    %{ $self->_request_options },
  );
}


sub get {
  my ($self, $name, %opts) = @_;
  croak "Image name required" unless $name;
  # `raw` and `on_chunk` are the same promise made twice -- hand the response
  # bytes over undecoded -- so only one of them is sent: with a callback there
  # is no return value for `raw` to describe.
  return $self->client->get("/images/$name/get",
    %{ $self->_request_options },
    exists $opts{on_chunk} ? ( on_chunk => $opts{on_chunk} ) : ( raw => 1 ));
}


sub get_all {
  my ($self, @names) = @_;

  # The list form has nowhere to put an option: get_all('a', 'b') is names all
  # the way down, and a trailing `on_chunk => sub {...}` in it would be two
  # more image names as far as this method can tell. So options ride behind
  # the ArrayRef form, which already exists for exactly one list.
  my %opts;
  if (ref $names[0] eq 'ARRAY') {
    my $list = shift @names;
    croak __PACKAGE__ . '->get_all takes options as pairs after the ArrayRef '
      . 'of names; got an odd number of them' if @names % 2;
    %opts  = @names;
    @names = @$list;
  }

  croak "At least one image name required" unless @names;
  # `names` is a repeated query parameter -- names=a&names=b -- and nothing
  # else is accepted: measured against Podman 5.4.2, the comma-joined spelling
  # answers 500 with 'parsing reference "alpine:3,registry:2": invalid
  # reference format'. An ArrayRef param value is exactly that repetition;
  # _request escapes each element with its own _uri_encode, which leaves `/`
  # and `:` raw so an image reference survives intact.
  return $self->client->get('/images/get', params => { names => \@names },
    %{ $self->_request_options },
    exists $opts{on_chunk} ? ( on_chunk => $opts{on_chunk} ) : ( raw => 1 ));
}


sub load {
  my ($self, $tar, %opts) = @_;
  croak "Tar archive required (raw bytes or a scalar ref)" unless defined $tar;

  my %params;
  $params{quiet} = $opts{quiet} ? 1 : 0 if defined $opts{quiet};

  my $raw = ref $tar eq 'SCALAR' ? $$tar : $tar;

  return $self->client->_request('POST', '/images/load',
    raw_body     => $raw,
    content_type => 'application/x-tar',
    params       => \%params,
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $opts{on_event} ) : ( ndjson => 1 ),
  );
}


sub commit {
  my ($self, %opts) = @_;
  croak "container required" unless $opts{container};

  my %params;
  $params{container} = $opts{container};
  $params{repo}      = $opts{repo}    if defined $opts{repo};
  $params{tag}       = $opts{tag}     if defined $opts{tag};
  $params{comment}   = $opts{comment} if defined $opts{comment};
  $params{author}    = $opts{author}  if defined $opts{author};
  $params{pause}     = $opts{pause} ? 1 : 0 if defined $opts{pause};

  # `changes` is a repeated query parameter on the wire, but the engine parses
  # each value as a Dockerfile snippet and a snippet may span lines, so one
  # newline-joined value carries a list just as well. Measured against Podman
  # 5.4.2: changes=LABEL%20a%3Db%0AEXPOSE%208080 and two separate changes=
  # pairs produce the same image. The joined form is used because it fits the
  # transport's one-value-per-key params encoder.
  if (defined $opts{changes}) {
    $params{changes} = ref $opts{changes} eq 'ARRAY'
      ? join("\n", @{$opts{changes}})
      : $opts{changes};
  }

  return $self->client->post('/commit', $opts{config},
    params => \%params,
    %{ $self->_request_options },
  );
}


sub build_prune {
  my ($self, %opts) = @_;

  my %params;
  # The engine spells this one with a hyphen, and an unquoted
  # `keep-storage => $n` is not even valid Perl -- the fat comma quotes a
  # bareword identifier, and keep-storage is a subtraction. So keep_storage is
  # the documented spelling, the wire name is accepted beside it for anyone
  # copying out of the Engine reference, and the hyphen is what goes on the
  # wire. _uri_encode leaves `-` alone, so the key survives unmangled.
  my $keep_storage = $opts{keep_storage} // $opts{'keep-storage'};
  $params{'keep-storage'} = $keep_storage       if defined $keep_storage;
  $params{all}            = $opts{all} ? 1 : 0  if defined $opts{all};
  $params{filters}        = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};

  return $self->client->post('/build/prune', undef,
    params => \%params,
    %{ $self->_request_options },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Images - Docker Engine Images API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Build an image from a tar context
    use Path::Tiny;
    my $tar = path('context.tar')->slurp_raw;
    $docker->images->build(context => $tar, t => 'myapp:latest');

    # Pull an image
    $docker->images->pull(fromImage => 'nginx', tag => 'latest');

    # List images
    my $images = $docker->images->list;
    for my $image (@$images) {
        say $image->id;
        say join ', ', @{$image->repo_tags};
    }

    # Inspect image details
    my $image = $docker->images->inspect('nginx:latest');

    # Tag and push
    $docker->images->tag('nginx:latest', repo => 'myrepo/nginx', tag => 'v1');
    $docker->images->push('myrepo/nginx', tag => 'v1');

    # Remove image
    $docker->images->remove('nginx:latest', force => 1);

    # Snapshot a container into an image
    my $new = $docker->images->commit(container => $id, repo => 'myapp', tag => 'snap');

    # Air-gapped roundtrip: export here, carry the tar over, load there
    my $export = $docker->images->get('myapp:snap');   # raw tar bytes
    $docker->images->load($export);

    # Reclaim the build cache (not the same thing as prune)
    $docker->images->build_prune(all => 1);

=head1 DESCRIPTION

This module provides methods for managing Docker images including pulling,
listing, tagging, pushing to registries, and removal.

C<list> and C<inspect> return generated L<API::Docker::Type> objects carrying
the convenience methods of L<API::Docker::Role::Entity::Image>, so
C<< $image->tag >> and C<< $image->remove >> work on either. Which class each
returns, and where the two disagree, is below.

Accessed via C<< $docker->images >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->images->using(read_timeout => 5) >>.

=head2 The two image shapes

The daemon describes an image two ways and the swagger has two definitions
for it, so this class returns two classes:

=over

=item * L</list> returns L<API::Docker::Type::ImageSummary> objects -- one
per entry of C<GET /images/json>.

=item * L</inspect> returns an L<API::Docker::Type::ImageInspect> -- the body
of C<GET /images/{name}/json>.

=back

They overlap but do not line up, and the field names are the swagger's own
spelling in snake_case (C<Id> is C<< ->id >>, C<RepoTags> is
C<< ->repo_tags >>, C<SharedSize> is C<< ->shared_size >>). The differences
worth knowing before reading a value off the wrong one:

=over

=item * C<< ->created >> is an integer Unix epoch on a summary and an
RFC 3339 string on an inspect. Same field name, two types -- C<Int> and
C<Str> in the model, which is the swagger's own answer, not a normalisation
this client applies. The same split a container has, see
L<API::Docker::API::Containers/"The two container shapes">.

=item * The parent layer is C<< ->parent_id >> on a summary and
C<< ->parent >> on an inspect. Both are empty for an image pulled from a
registry rather than built locally, and the swagger marks the inspect one
deprecated.

=item * C<< ->labels >> is top-level on a summary only. An inspect carries
the labels under C<< ->config->labels >>, where C<< ->config >> is the
L<API::Docker::Type::ImageConfig> the image runs containers with --
C<< ->cmd >>, C<< ->env >>, C<< ->entrypoint >>, C<< ->exposed_ports >> and
the rest.

=item * C<< ->containers >> (how many containers use the image) and
C<< ->shared_size >> come from a summary only. The swagger says of both that
C<-1> means the value was not calculated, and of C<SharedSize> that it is not
calculated by default -- so treat C<-1> as "unknown", not as a count.

=item * C<< ->architecture >>, C<< ->os >>, C<< ->os_version >>,
C<< ->variant >>, C<< ->author >>, C<< ->comment >>, C<< ->docker_version >>,
C<< ->config >>, C<< ->root_fs >>, C<< ->graph_driver >> and
C<< ->metadata >> come from an inspect only.

=item * C<< ->id >>, C<< ->repo_tags >>, C<< ->repo_digests >>, C<< ->size >>,
C<< ->descriptor >> and C<< ->manifests >> are on both and mean the same
thing. The swagger declares every field of a summary required and no field of
an inspect, which the model records but does not enforce -- see
L<API::Docker::Type/"C<since> is documentation">.

=back

There is no C<< ->virtual_size >>: the swagger dropped C<VirtualSize> from
both definitions after v1.44, and engines that still send it -- the Podman on
this machine does -- have it kept verbatim in
C<< ->unknown_fields->{VirtualSize} >>, where C<TO_JSON> writes it back
unchanged. F<t/type_fixture_passthrough.t> pins that.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $images = $images->list(all => 1);

List images. Returns an ArrayRef of L<API::Docker::Type::ImageSummary>
objects, each carrying the methods of L<API::Docker::Role::Entity::Image>.

Options:

=over

=item * C<all> - Show all images (default hides intermediate images)

=item * C<digests> - Include digest information

=item * C<filters> - HashRef of filter name to ArrayRef of string values, e.g.
C<< { dangling => ['true'] } >>. Shape-checked and normalised by
L<API::Docker::Role::Filters>

=back

=head2 build

    # Build from a tar archive
    my $tar_data = path('context.tar')->slurp_raw;
    my $events = $docker->images->build(
        context    => $tar_data,
        t          => 'myimage:latest',
        dockerfile => 'Dockerfile',
    );

    # Build with build args
    my $events = $docker->images->build(
        context   => $tar_data,
        t         => 'myapp:v1',
        buildargs => { APP_VERSION => '1.0' },
        nocache   => 1,
    );

Build an image from a tar archive containing a Dockerfile and build context.

The C<context> parameter is required and must contain the raw bytes of a tar
archive (or a scalar reference to one).

Returns an ArrayRef of build events, one per object in the engine's
newline-delimited JSON stream, even when the stream carried a single object
(C<< q => 1 >> produces exactly one). A successful build returns; a failed one
croaks.

    my $events = $images->build(context => $tar, t => 'myapp:latest');
    my ($aux) = grep { $_->{aux} } @$events;
    my $image_id = $aux->{aux}{ID};

The engine answers a failed build with HTTP 200 and reports the failure as an
C<errorDetail> object inside the stream, so nothing about the response status
says the build broke. This method used to return that stream like any other
and leave the scan to the caller, which meant a caller who did not know to
scan reported a broken build as a success. It now croaks with an
L<API::Docker::Error::Stream> instead:

    my $events = eval { $images->build(context => $tar, t => 'myapp:latest') };
    if (my $err = $@) {
        warn "$err";               # the reason, with Carp's location suffix
        for my $event (@{ $err->events }) {   # the build output up to the failure
            print $event->{stream} if defined $event->{stream};
        }
    }

The exception stringifies to what a plain C<croak> would have produced, so
existing C<eval>-and-inspect-C<$@> code needs no change.

Options:

=over

=item * C<context> - Tar archive bytes (required)

=item * C<dockerfile> - Path to Dockerfile within the archive (default: C<Dockerfile>)

=item * C<t> - Tag for the image (e.g. C<name:tag>)

=item * C<q> - Suppress verbose build output

=item * C<nocache> - Do not use cache when building

=item * C<pull> - Always pull base image

=item * C<rm> - Remove intermediate containers (default: true)

=item * C<forcerm> - Always remove intermediate containers

=item * C<buildargs> - HashRef of build-time variables

=item * C<labels> - HashRef of labels to set on the image

=item * C<memory> - Memory limit in bytes

=item * C<memswap> - Total memory (memory + swap), -1 to disable swap

=item * C<cpushares> - CPU shares (relative weight)

=item * C<cpusetcpus> - CPUs to use (e.g. C<0-3>, C<0,1>)

=item * C<cpuperiod> - CPU CFS period (microseconds)

=item * C<cpuquota> - CPU CFS quota (microseconds)

=item * C<shmsize> - Size of /dev/shm in bytes

=item * C<networkmode> - Network mode during build

=item * C<platform> - Platform (e.g. C<linux/amd64>)

=item * C<target> - Multi-stage build target

=item * C<registry_config> - Registry credentials for the base images the build
pulls, sent as C<X-Registry-Config>. A HashRef mapping each registry hostname
to its AuthConfig --
C<< { 'registry.example:5000' => { username => 'me', password => 'secret' } } >>
-- so a C<FROM private.registry/...> can authenticate, and a build drawing from
several registries can carry all of them at once. A pre-encoded base64 string
is also accepted. Sent only when given. This is B<not> C<auth>/C<X-Registry-Auth>,
which carries a single AuthConfig; C</build> uses the map form. See
L<API::Docker::Role::RegistryAuth>

=item * C<on_event> - CodeRef called with each build event as it arrives,
instead of the ArrayRef being collected and returned; see below

=back

=head2 Progress as it arrives

Without a callback the whole stream is read before anything is parsed, so a
build that takes two minutes is two minutes of silence followed by all of its
output at once. Pass C<on_event> and the events are handed over as the daemon
sends them:

    my $summary = $images->build(
        context  => $tar,
        t        => 'myapp:latest',
        on_event => sub {
            my ($event, $stop) = @_;
            print $event->{stream} if defined $event->{stream};
        },
    );

    $summary;   # { delivered => 41, stopped => 0 }

With a callback the return value is that summary HashRef, not the events:
C<delivered> is how many went to the callback, C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated,
so a caller that wants the C<aux> event with the image id in it must keep that
event itself as it goes by. See
L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

The same section applies to L</pull>, L</push> and L</load>, which take
C<on_event> on the same terms.

=head3 A failed build still croaks, one event earlier

The C<errorDetail> check runs either way, so a failed build croaks with an
L<API::Docker::Error::Stream> on both paths. What differs is when, and what
the exception carries:

=over

=item * Buffered, the stream is scanned once it is complete, and
C<< $err->events >> is the B<whole> event list -- all the build output that
led up to the failure.

=item * Streamed, the check runs per event, so the croak happens at the event
that reports the failure rather than when the daemon eventually closes. The
exception then carries B<that one event> alone: a callback stream keeps no
history, having handed every earlier event to the callback already. The
failing event itself is not delivered.

=back

So a caller that reads the progress out of C<< $err->events >> must, on this
path, collect it in the callback instead:

    my @output;
    my $summary = eval {
        $images->build(context => $tar, t => 'myapp:latest',
            on_event => sub { push @output, $_[0] });
    };
    if (my $err = $@) {
        warn "$err";               # the reason, as before
        # $err->events is the failing event; @output is what preceded it
    }

=head2 pull

    my $events = $images->pull(fromImage => 'nginx', tag => 'latest');
    my $events = $images->pull(fromImage => 'nginx:1.25');   # tag rides in the name
    my $events = $images->pull(fromImage => 'alpine@sha256:...');  # by digest

Pull an image from a registry.

C<tag> defaults to C<latest> B<only when C<fromImage> carries no tag or digest
of its own>. The engine appends C<tag> to the reference rather than treating it
as a fallback, so defaulting it onto an already-qualified name breaks the pull:
measured against Docker 29.7.2 (API 1.55) C<< pull(fromImage => 'nginx:1.25')
>> would silently fetch C<nginx:latest> and report success, and against Podman
5.8.4 (compat API 1.44) the same request answers C<500 invalid reference
format> for C<nginx:1.25:latest>. A digest reference breaks the same way on
both. So C<tag> is sent only if given explicitly, or defaulted to C<latest>
when the name carries neither a C<:tag> (in the segment after the last C</>)
nor an C<@digest>. A registry C<host:port/> prefix is not mistaken for a tag.

Returns an ArrayRef of progress events, one per object in the engine's
newline-delimited JSON stream, even when the stream carried a single object.

A failed pull croaks either way, but which way depends on the engine, so do
not write code that expects one of them:

=over

=item * Docker reports it in the stream. The response is HTTP 200 and the
failure is an C<errorDetail> object among the progress events; this method
croaks with an L<API::Docker::Error::Stream>, whose C<< ->events >> holds the
progress that preceded the failure.

=item * Podman reports it in the status line. Measured against the rootless
socket (5.4.2, API 1.41): pulling a repository that does not exist answers
C<403 Forbidden> with C<< {"message":"denied: requested access to the resource
is denied"} >>, and an existing repository with a missing tag answers
C<404 Not Found> with C<< {"message":"manifest unknown: manifest unknown"} >>.
Neither reaches the stream at all -- the transport's own status handling
croaks with an L<API::Docker::Error::HTTP> -- which is that same string to
anything inspecting C<$@> as text -- first.

=back

Catching L<API::Docker::Error::Stream> specifically is therefore not a
reliable way to catch a failed pull. C<eval> and inspect C<$@> as a string,
which both cases satisfy.

Options:

=over

=item * C<fromImage> - Image name to pull (required)

=item * C<tag> - Tag to pull. Defaulted to C<latest> only when C<fromImage>
carries no tag or digest of its own; see above

=item * C<auth> - Registry credentials for pulling from a private registry,
sent as C<X-Registry-Auth>. A HashRef of the usual keys (C<username>,
C<password>, C<serveraddress>, or C<identitytoken>) or a pre-encoded base64
string, exactly as L</push> takes it. Unlike C<push>, the header is sent
B<only> when C<auth> is given -- an anonymous pull carries none, which the
engine reads as the anonymous case. See L<API::Docker::Role::RegistryAuth>

=item * C<on_event> - CodeRef called with each progress event as it arrives,
instead of the ArrayRef being collected and returned. The return value is then
the summary HashRef and a stream failure croaks one event in, exactly as for
L</build>; see L</"Progress as it arrives">

=back

=head2 inspect

    my $image = $images->inspect('nginx:latest');

Get detailed information about an image. Returns an
L<API::Docker::Type::ImageInspect>, which is B<not> the class L</list>
returns -- see L</"The two image shapes">.

=head2 history

    my $history = $images->history('nginx:latest');

Get image history (layers). Returns ArrayRef of layer information.

=head2 push

    my $events = $images->push('myrepo/nginx', tag => 'v1');
    $images->push('myrepo/nginx', auth => {
        username      => 'me',
        password      => 'secret',
        serveraddress => 'https://index.docker.io/v1/',
    });

Push an image to a registry. Optionally specify C<tag>.

Returns an ArrayRef of progress events, one per object in the engine's
newline-delimited JSON stream, even when the stream carried a single object.

A failed push croaks, by one of two routes depending on the engine -- an
unauthorised push to a private registry is the common case, and it is exactly
the one that must not be reported as a success.

Docker reports it inside a 200 stream as an C<errorDetail> object, which
croaks with an L<API::Docker::Error::Stream> carrying the progress events.
Podman puts an C<errorDetail> body behind a real error status instead:
measured against the rootless socket (5.4.2, API 1.41), a push to an
unreachable registry answers C<500 Internal Server Error> with
C<< {"errorDetail":{"message":"... connection refused"},"error":"..."} >>, so
the transport's status handling croaks with an L<API::Docker::Error::HTTP> --
which is that same string to anything inspecting C<$@> as text -- before the
stream is ever decoded. That body carries no C<message> key, so the whole
JSON object ends up as the croak text.

Either way the failure is loud. Inspect C<$@> as a string rather than testing
for the exception class, which only the first route produces.

The Docker Engine requires an C<X-Registry-Auth> header on every push,
even for anonymous attempts; the header is always sent. Pass C<auth> as
a hashref of credentials (typical keys: C<username>, C<password>,
C<serveraddress>, or C<identitytoken>), or as a pre-encoded base64 string.
Without C<auth> the header carries an empty JSON object.

Options:

=over

=item * C<tag> - Tag to push

=item * C<auth> - Registry credentials, as above

=item * C<on_event> - CodeRef called with each progress event as it arrives --
layer by layer, rather than the whole upload in one silence -- instead of the
ArrayRef being collected and returned. The return value is then the summary
HashRef and a stream failure croaks one event in, exactly as for L</build>;
see L</"Progress as it arrives">

=back

=head2 tag

    $images->tag('nginx:latest', repo => 'myrepo/nginx', tag => 'v1');

Tag an image with a new repository and/or tag name.

=head2 remove

    $images->remove('nginx:latest', force => 1);

Remove an image.

Options:

=over

=item * C<force> - Force removal

=item * C<noprune> - Do not delete untagged parents

=back

=head2 search

    my $results = $images->search('nginx', limit => 25);

Search Docker Hub for images. Returns ArrayRef of search results.

Options:

=over

=item * C<limit> - Maximum number of results

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<is-official>, C<is-automated> and C<stars> here. The boolean
ones want the string, C<< { 'is-official' => ['true'] } >>, and C<stars> a
number written as one -- L<API::Docker::Role::Filters> takes care of both and
croaks on a shape the daemon would refuse

=back

=head2 prune

    my $result = $images->prune(filters => { dangling => ['true'] });

Delete unused images. Returns hashref with C<ImagesDeleted> and C<SpaceReclaimed>.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<dangling>, C<until> and C<label> here. Shape-checked and
normalised by L<API::Docker::Role::Filters>

=back

=head2 get

    use Path::Tiny;
    my $tar = $images->get('alpine:3');
    path('alpine.tar')->spew_raw($tar);

Export one image, and the history behind it, as a tar archive -- the endpoint
behind C<docker image save>. Together with L</load> it is the only way in or
out of a daemon that does not go through a registry.

B<The return value is raw bytes, not a decoded structure.> The engine answers
with the tar stream itself, and the transport is told to hand it back
untouched (C<< raw => 1 >>), so what arrives is byte for byte what the daemon
wrote. Write it with a binary-safe file handle -- C<< path(...)->spew_raw >>,
or C<binmode> on a handle of your own. Treating it as text corrupts it, and
nothing about the value announces that it is binary.

The archive holds one tarball per layer, a config JSON per image,
C<manifest.json> and C<repositories>. Measured against Podman 5.4.2 (API
1.41): the response is chunked with
C<< Content-Type: application/octet; charset=us-ascii >>, where Docker sends
C<application/x-tar> -- the transport looks at neither, so the difference does
not reach the caller. Exporting C<alpine:3> through this method produced bytes
md5-identical to what C<curl --unix-socket> wrote for the same request, all
8705536 of them, so the chunked reader is binary-clean.

An unknown image croaks. On the same engine that is C<404 Not Found> with
C<< {"message":"failed to find image ...: image not known"} >>.

=head2 Exporting without buffering the archive

The whole archive is buffered in memory before it is returned, so exporting a
large image costs its full size in RAM. Pass C<on_chunk> and the bytes are
handed over as they arrive instead, and nothing is kept:

    use Path::Tiny;
    my $out = path('alpine.tar')->openw_raw;
    my $summary = $images->get('alpine:3',
        on_chunk => sub { print {$out} $_[0] });
    close $out;

    $summary;   # { delivered => 266, stopped => 0 }

The units are whatever the transport read, not a fixed size: a chunk boundary
carries no meaning in a tar stream, and the only guarantee is that
concatenating them in order gives the same bytes the buffered call returns.
Write them to a binary-safe handle, exactly as for the buffered value.

Measured against Podman 5.4.2 (API 1.41): exporting C<alpine:3> this way
delivered its 8705536 bytes in 266 pieces, md5-identical to what the buffered
call returns for the same request, with no more than one piece held at a time.

With a callback the return value is the summary HashRef
C<< { delivered => N, stopped => 0|1 } >>, not the archive: C<delivered> is
how many pieces went to the callback, C<stopped> is 1 when the callback ended
the transfer. Stopping leaves a B<truncated> archive behind -- the export is
one tar stream, not a sequence of independent records -- so stop only to
abandon it. See
L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

Options:

=over

=item * C<on_chunk> - CodeRef called with each piece of the archive as it
arrives, instead of the whole thing being returned

=back

=head2 get_all

    my $tar = $images->get_all('alpine:3', 'registry:2');
    my $tar = $images->get_all([ 'alpine:3', 'registry:2' ]);

Export several images into one tar archive. Takes the names as a list or as a
single ArrayRef; at least one is required.

B<The return value is raw bytes>, exactly as for L</get> -- see there for what
that means for writing it out.

C<manifest.json> inside the archive carries one entry per image, so a single
tar can be carried to another host and loaded in one L</load> call. Measured
against Podman 5.4.2 (API 1.41): asking for no names at all answers
C<400 Bad Request> with C<< {"message":"no images to download"} >>.

C<on_chunk> works here exactly as it does for L</get> -- several images make a
bigger archive, so this is where not buffering it matters most -- but it can
only be passed with the ArrayRef form:

    my $summary = $images->get_all([ 'alpine:3', 'registry:2' ],
        on_chunk => sub { print {$out} $_[0] });

The list form takes names and nothing else: a trailing option pair in it would
be indistinguishable from two more image names. Options after the ArrayRef
must come in pairs; an odd number croaks.

A transport bound is not one of those options: it goes on the resource class,
which works with either form -- C<< $docker->images->using(read_timeout => 5)
->get_all('alpine:3') >>, see L<API::Docker::Role::Using>.

Measured against Podman 5.4.2 (API 1.41): C<alpine:3> and C<registry:2>
together came to 34725888 bytes in 1060 pieces, none of which had to be held.

=head2 load

    use Path::Tiny;
    my $events = $images->load(path('alpine.tar')->slurp_raw);

    for my $event (@$events) {
        print $event->{stream} if defined $event->{stream};
    }

Import a tar archive produced by L</get> or L</get_all> -- the endpoint behind
C<docker image load>. The archive is the request body; pass it as raw bytes or
as a scalar reference to them, the way L</build> takes its context.

Returns an ArrayRef of progress events, one per object in the engine's
newline-delimited JSON stream, even when the stream carried a single object.
The last of them names what was imported:

    my ($loaded) = grep { ($_->{stream} // '') =~ /^Loaded image/ } @$events;

Options:

=over

=item * C<quiet> - Suppress the per-layer progress detail in the response
stream

=item * C<on_event> - CodeRef called with each progress event as it arrives,
instead of the ArrayRef being collected and returned. The return value is then
the summary HashRef and a stream failure croaks one event in, exactly as for
L</build>; see L</"Progress as it arrives">

=back

C<quiet> changes how much the engine says, not what this method returns: the
body stays newline-delimited JSON and the return stays an ArrayRef either way.
B<Podman ignores it entirely> -- measured against 5.4.2 (API 1.41), C<quiet>
unset, C<0> and C<1> all produce the identical single
C<< {"stream":"Loaded image: ..."} >> object. Should an engine answer a quiet
load with a body of no bytes at all, the transport still returns C<[]>, not
C<undef> -- the C<ndjson> branch in L<API::Docker::Role::HTTP/_request> runs
before the empty-body check that would return C<undef>, so a caller that
iterates the result unconditionally needs no guard for this case.

A failed load croaks, but by which route depends on the engine, the same split
L</pull> and L</push> have. Docker reports it as an C<errorDetail> object
inside a 200 stream, which croaks with an L<API::Docker::Error::Stream>
carrying the events. Podman reports it in the status line instead: measured
against 5.4.2, a body that is not an image archive answers C<500 Internal
Server Error> with C<< {"message":"failed to load image: payload does not
match any of the supported image formats: ..."} >>, and the transport's status
handling croaks with an L<API::Docker::Error::HTTP> -- which is that same
string to anything inspecting C<$@> as text -- before any stream is decoded.
Inspect C<$@> as a string rather than testing for the exception class.

The archive is sent as one buffered request body, so loading a large image
costs its full size in RAM.

=head2 commit

    my $result = $images->commit(
        container => $container_id,
        repo      => 'myapp',
        tag       => 'snapshot',
        comment   => 'after the migration ran',
    );
    my $image_id = $result->{Id};

    # With a config override and Dockerfile instructions
    $images->commit(
        container => $container_id,
        repo      => 'myapp',
        tag       => 'v2',
        config    => { Cmd => [ '/bin/sh' ], Labels => { built => 'here' } },
        changes   => [ 'EXPOSE 8080', 'LABEL stage=release' ],
    );

Create an image from a container's current filesystem. This is the one
image-producing path that does not go through a build context, and it is how a
caller snapshots a container it has been exec-ing into.

Returns the raw daemon response, a HashRef with an C<Id> key. Measured against
Podman 5.4.2 (API 1.41) the status is C<201 Created> and C<Id> is a bare hex
digest with no C<sha256:> prefix; Docker prefixes it. Do not compare it
literally against an id from C<inspect> without normalising.

Options:

=over

=item * C<container> - Container id or name to commit (required)

=item * C<repo> - Repository for the new image, e.g. C<myapp>

=item * C<tag> - Tag for the new image

=item * C<comment> - Commit message stored in the image history

=item * C<author> - Author, e.g. C<< Jane <jane@example.com> >>

=item * C<pause> - Pause the container while committing (engine default is true)

=item * C<changes> - Dockerfile instructions to apply to the new image, as a
single string or an ArrayRef of them; an ArrayRef is joined with newlines,
which is what the engine's parser expects

=item * C<config> - HashRef of container configuration to override on the new
image (C<Cmd>, C<Env>, C<Labels>, C<ExposedPorts>, ...), sent as the request
body. Measured against Podman 5.4.2: C<Cmd> replaces the container's, C<Env>
is merged onto the environment the container inherited, and a C<Labels> here
lands alongside a C<LABEL> given in C<changes> -- the two are applied
together, not one instead of the other

=back

=head2 build_prune

    my $result = $images->build_prune(all => 1);
    my $freed  = $result->{SpaceReclaimed};

    # Keep 5 GB of cache
    $images->build_prune(keep_storage => 5 * 1024 * 1024 * 1024);

Clear the BuildKit build cache. B<This is not L</prune>>, and the two are not
interchangeable: L</prune> deletes unused I<images>, this deletes the
intermediate I<build cache> that L</build> writes. Neither touches the other's
storage, and on a machine that builds often the build cache is usually the
larger of the two.

Returns the raw daemon response, a HashRef with C<CachesDeleted> and
C<SpaceReclaimed>.

B<Podman does not implement this endpoint.> Measured against 5.4.2 (API 1.41):
C<POST /build/prune> answers C<404 Not Found> with a C<text/plain> body of
C<Not Found> -- not the JSON C<< {"message":...} >> shape its other errors use
-- at every version prefix tried, and there is no C<libpod> equivalent either.
The transport croaks with C<Docker API error (404): Not Found>, the plain body
verbatim, because it is not JSON to unwrap. A caller that must work on both
engines has to treat that 404 as "no build cache to clear here" rather than as
a transport fault.

Options:

=over

=item * C<keep_storage> - Bytes of cache to keep. Sent as the engine's
C<keep-storage>, which is also accepted as the option name; the underscore
form exists because the hyphenated one has to be quoted in a Perl hash

=item * C<all> - Remove all cache, not just the dangling entries

=item * C<filters> - HashRef of filters, e.g. C<< { until => ['24h'] } >>;
values are ArrayRefs of strings, shape-checked and normalised by
L<API::Docker::Role::Filters>, and passed to the transport unencoded because
it JSON-encodes a HashRef params value itself

=back

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Role::Entity::Image> - the convenience methods the
returned objects carry

=item * L<API::Docker::Type::ImageSummary> - the fields C<list> returns

=item * L<API::Docker::Type::ImageInspect> - the fields C<inspect> returns

=item * L<API::Docker::Role::RegistryAuth> - the C<X-Registry-Auth>
encoding C<push> uses, shared with the other registry-facing endpoints

=item * L<API::Docker::Error::Stream> - Raised by C<build>, C<pull>, C<push>
and C<load>

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
