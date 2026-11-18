package API::Docker::API::Plugins;
# ABSTRACT: Docker Engine Plugins API
our $VERSION = '0.006';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::RegistryAuth',
  'API::Docker::Role::Using';
use API::Docker::Role::Entity::Plugin;
use API::Docker::Type::Plugin;
use Carp qw( croak );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


# The class is the caller's argument, as it is on the resource classes whose
# list and inspect really are two definitions -- here both are the swagger's
# one `Plugin`, and passing it keeps the seam in the same place.
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

# The plugin router calls registry.DecodeAuthConfig on the header and
# discards the error -- "Ignore invalid AuthConfig to increase compatibility
# with the existing API" -- so unlike /images/{name}/push, which rejects a
# missing header, an anonymous plugin operation needs no header at all. It is
# sent only when the caller asked for it. The encoding is
# API::Docker::Role::RegistryAuth; what stays here is the policy.
sub _auth_headers {
  my ($self, $opts) = @_;
  return () unless defined $opts->{auth};
  return (headers => { 'X-Registry-Auth' => $self->_registry_auth_header($opts->{auth}) });
}

sub _privileges_body {
  my ($self, $method, $remote, %opts) = @_;

  return $self->privileges($remote, %opts) if $opts{accept_privileges};

  my $privileges = $opts{privileges};
  croak __PACKAGE__ . '->' . $method . ' requires privileges: fetch them with '
    . '->privileges(' . $remote . ') and pass them back as privileges => '
    . '$privileges, or pass accept_privileges => 1 to grant whatever the '
    . 'plugin asks for. The engine compares the list you send against the one '
    . 'the plugin demands and fails the operation when they differ'
    unless defined $privileges;

  croak __PACKAGE__ . '->' . $method . ' privileges must be an ArrayRef'
    unless ref $privileges eq 'ARRAY';

  return $privileges;
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  my $result = $self->client->get('/plugins',
    params => \%params,
    %{ $self->_request_options },
  );
  return $self->_wrap_list('API::Docker::Type::Plugin', $result // []);
}


sub privileges {
  my ($self, $remote, %opts) = @_;
  croak __PACKAGE__ . '->privileges remote reference required' unless $remote;

  my $result = $self->client->get('/plugins/privileges',
    params => { remote => $remote },
    $self->_auth_headers(\%opts),
    %{ $self->_request_options },
  );

  # A plugin that demands nothing answers a bare `null`: computePrivileges
  # builds its result with `var privileges types.PluginPrivileges` and
  # appends only what the config asks for, so a nil Go slice reaches the
  # wire. The transport decodes that to undef, which no caller can iterate
  # and which accept_privileges => 1 would post straight back to
  # /plugins/pull as a JSON null. Normalised to the empty list it means.
  return [] unless ref $result eq 'ARRAY';
  return $result;
}


sub install {
  my ($self, $remote, %opts) = @_;
  croak __PACKAGE__ . '->install remote reference required' unless $remote;

  my $privileges = $self->_privileges_body('install', $remote, %opts);

  my %params = ( remote => $remote );
  $params{name} = $opts{name} if defined $opts{name};

  # exists, not truth: an unset callback is a caller bug, and falling back to
  # the buffered path for it would hand a long pull back as silence.
  return $self->client->post('/plugins/pull', $privileges,
    params => \%params,
    $self->_auth_headers(\%opts),
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $opts{on_event} ) : ( ndjson => 1 ),
  );
}


sub inspect {
  my ($self, $name) = @_;
  croak __PACKAGE__ . '->inspect plugin name required' unless $name;
  return $self->_wrap('API::Docker::Type::Plugin',
    $self->client->get("/plugins/$name/json",
      %{ $self->_request_options },
    ));
}


sub remove {
  my ($self, $name, %opts) = @_;
  croak __PACKAGE__ . '->remove plugin name required' unless $name;
  my %params;
  $params{force} = $opts{force} ? 1 : 0 if defined $opts{force};
  return $self->client->delete_request("/plugins/$name",
    params => \%params,
    %{ $self->_request_options },
  );
}


sub enable {
  my ($self, $name, %opts) = @_;
  croak __PACKAGE__ . '->enable plugin name required' unless $name;
  # Always sent, and not conditional on the caller passing it: the daemon
  # parses this parameter with strconv.Atoi and has no default, so an absent
  # timeout is parsed as the empty string and answers 400. See the POD.
  my %params = ( timeout => $opts{timeout} // 0 );
  return $self->client->post("/plugins/$name/enable", undef,
    params => \%params,
    %{ $self->_request_options },
  );
}


sub disable {
  my ($self, $name, %opts) = @_;
  croak __PACKAGE__ . '->disable plugin name required' unless $name;
  my %params;
  $params{force} = $opts{force} ? 1 : 0 if defined $opts{force};
  return $self->client->post("/plugins/$name/disable", undef,
    params => \%params,
    %{ $self->_request_options },
  );
}


sub upgrade {
  my ($self, $name, %opts) = @_;
  croak __PACKAGE__ . '->upgrade plugin name required' unless $name;

  my $remote = $opts{remote} // $name;
  my $privileges = $self->_privileges_body('upgrade', $remote, %opts);

  return $self->client->post("/plugins/$name/upgrade", $privileges,
    params => { remote => $remote },
    $self->_auth_headers(\%opts),
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $opts{on_event} ) : ( ndjson => 1 ),
  );
}


sub push {
  my ($self, $name, %opts) = @_;
  croak __PACKAGE__ . '->push plugin name required' unless $name;
  return $self->client->post("/plugins/$name/push", undef,
    $self->_auth_headers(\%opts),
    %{ $self->_request_options },
    exists $opts{on_event} ? ( on_event => $opts{on_event} ) : ( ndjson => 1 ),
  );
}


sub configure {
  my ($self, $name, @settings) = @_;
  croak __PACKAGE__ . '->configure plugin name required' unless $name;

  # One ArrayRef or a plain list, and nothing after either: this method reads
  # no options at all. The ArrayRef form used to be where the transport bounds
  # went, because a trailing `read_timeout => 2` in the plain list would be two
  # more settings as far as this method can tell -- they now go on the resource
  # class instead (karr k74), and what is left is a form, not a split.
  if (ref $settings[0] eq 'ARRAY') {
    my $list = shift @settings;
    croak __PACKAGE__ . '->configure takes nothing after the ArrayRef of '
      . 'settings; a transport bound goes on the resource class, as '
      . '$docker->plugins->using(read_timeout => 5)->configure(...)'
      if @settings;
    @settings = @$list;
  }

  croak __PACKAGE__ . '->configure requires at least one setting, as an '
    . 'ArrayRef or a list of "KEY=value" strings' unless @settings;

  croak __PACKAGE__ . '->configure settings must be plain strings'
    if grep { ref $_ } @settings;

  return $self->client->post("/plugins/$name/set", \@settings,
    %{ $self->_request_options },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Plugins - Docker Engine Plugins API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # List installed plugins
    my $plugins = $docker->plugins->list;

    # Install: look at what the plugin demands, then grant exactly that
    my $privileges = $docker->plugins->privileges('vieux/sshfs:latest');
    $docker->plugins->install('vieux/sshfs:latest',
        privileges => $privileges,
    );
    $docker->plugins->enable('vieux/sshfs:latest');

    # Inspect
    my $plugin = $docker->plugins->inspect('vieux/sshfs:latest');
    say $plugin->name, $plugin->enabled ? ' (enabled)' : ' (disabled)';

    # Configure, upgrade, disable, remove
    $docker->plugins->configure('vieux/sshfs:latest', ['DEBUG=1']);
    $docker->plugins->upgrade('vieux/sshfs:latest', privileges => $privileges);
    $docker->plugins->disable('vieux/sshfs:latest');
    $docker->plugins->remove('vieux/sshfs:latest');

=head1 DESCRIPTION

This module provides access to the Docker managed-plugin endpoints
(C</plugins>).

Accessed via C<< $docker->plugins >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->plugins->using(read_timeout => 5) >>.

=head2 Installing is two calls, and the engine enforces it

C<< POST /plugins/pull >> takes the list of privileges the plugin demands
B<in its request body>, and the daemon compares that list against the one it
computes from the plugin's own config. They must match exactly -- same
length, same names, same values -- or the install fails with
C<incorrect privileges>. A plugin runs with the host access it asked for, so
the round trip exists to make somebody look at that access before granting
it.

L</privileges> is the first call, L</install> the second:

    my $privileges = $docker->plugins->privileges('vieux/sshfs:latest');
    # inspect $privileges here -- it is an ArrayRef of
    #   { Name => 'network', Description => '...', Value => ['host'] }
    $docker->plugins->install('vieux/sshfs:latest', privileges => $privileges);

C<install> B<requires> C<privileges> and croaks without it, which is stricter
than the engine: the daemon's own body parser treats a missing body as an
empty privilege list rather than an error, so a blind install of a plugin
that happens to demand nothing would quietly succeed and one that demands
C<network: host> would fail with an error naming neither. Passing
C<< accept_privileges => 1 >> makes C<install> perform the first call itself
and hand the answer straight back -- a blanket grant, spelled out at the call
site so it is greppable.

The same applies to L</upgrade>, which takes the same body.

=head2 Not available on Podman

Measured against the rootless Podman socket (5.4.2, API 1.41): B<none> of the
C</plugins> endpoints exist there. C<< GET /v1.41/plugins >> answers
C<404 Not Found> with
C<< {"cause":"","message":"Path /v1.41/plugins is not supported","response":0} >>
(the C<1.41> there is this client's negotiated API version, echoed back from
the request path -- it moves with negotiation, not a fixed string in the
daemon's error text),
and every other path in this family -- C</plugins/privileges>,
C</plugins/pull>, C</plugins/{name}/json>, C</plugins/{name}/enable> and the
rest -- answers a bare C<404 Not Found> as C<text/plain>, meaning the compat
layer has no route registered for them at all. Managed plugins are a Docker
feature; Podman's own plugin model is not served here. Everything in this
class therefore needs a real Docker daemon.

=head2 What this class returns

L</list> and L</inspect> return L<API::Docker::Type::Plugin> objects carrying
the convenience methods of L<API::Docker::Role::Entity::Plugin>, following
the C<list>/C<inspect> convention every other resource class here follows.
It is B<one> class for both, where containers and images have two: the
swagger answers C<GET /plugins> with an array of the C<Plugin> definition and
C<GET /plugins/{name}/json> with that same definition.

Field names are the swagger's own spelling in snake_case, and the nested
ones are generated classes rather than the raw HashRefs the old entity kept:
C<< $plugin->settings >> is an L<API::Docker::Type::Plugin::Settings> whose
C<< ->env >> is a list of C<KEY=value> strings, and C<< $plugin->config >> an
L<API::Docker::Type::Plugin::Config> whose C<< ->env >> is a list of
L<API::Docker::Type::PluginEnv> objects describing those same variables. The
entity's methods thread the plugin's name back through this class.

Everything else returns the decoded engine response as it came: L</privileges>
an ArrayRef of privilege HashRefs, L</install>, L</upgrade> and L</push> an
ArrayRef of progress events, and L</enable>, L</disable>, L</remove> and
L</configure> C<undef>.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $plugins = $plugins->list;
    my $enabled = $plugins->list(filters => { enabled => ['true'] });

List installed plugins. Returns an ArrayRef of L<API::Docker::Type::Plugin>
objects, each carrying the methods of L<API::Docker::Role::Entity::Plugin>.
An engine with no plugins installed answers C<[]>, never C<null>, so this is
an empty ArrayRef rather than C<undef>.

Options:

=over

=item * C<filters> - HashRef of filters, JSON-encoded by the transport. Values
are ArrayRefs of strings even for booleans -- L<API::Docker::Role::Filters>
shape-checks and normalises that, but not the names, which the daemon
validates itself

=back

The accepted filter names are C<enabled> and C<capability>. B<It is C<enabled>,
not C<enable>> -- the published Engine API reference says C<enable>, and the
daemon validates plugin filter names against its own list, so the documented
spelling is refused outright rather than silently matching nothing. C<enabled>
takes C<['true']> or C<['false']>; C<capability> takes a capability name such
as C<['volumedriver']>.

=head2 privileges

    my $privileges = $plugins->privileges('vieux/sshfs:latest');

Get the privileges a plugin demands, without installing it. Returns an
ArrayRef of HashRefs:

    [ { Name => 'network', Description => '', Value => ['host'] },
      { Name => 'mount',   Description => '', Value => ['/var/lib/docker/plugins/'] } ]

This is the first half of the install; see L</"Installing is two calls, and
the engine enforces it">. Reading it is the point -- the result is what you
hand to L</install>, and the daemon accepts the install only if the two
lists agree.

A plugin that demands nothing answers with an empty ArrayRef.

The C<remote> reference is normalised by the daemon, so C<vieux/sshfs> and
C<docker.io/vieux/sshfs:latest> name the same plugin; C<:latest> is the
default when no tag is given.

Options:

=over

=item * C<auth> - Registry credentials for a plugin in a private registry;
HashRef of C<username> / C<password> / C<serveraddress> / C<identitytoken>,
or a pre-encoded base64 string. Sent as C<X-Registry-Auth>. The Engine API
reference does not document this header on this endpoint, but the daemon
reads it here exactly as it does on the pull

=back

=head2 install

    my $privileges = $plugins->privileges('vieux/sshfs:latest');
    $plugins->install('vieux/sshfs:latest', privileges => $privileges);

    # blanket grant, in one call
    $plugins->install('vieux/sshfs:latest', accept_privileges => 1);

Pull and install a plugin (C<< POST /plugins/pull >>). The plugin is installed
disabled -- call L</enable> afterwards.

C<privileges> is required. Without it this croaks and names both ways
forward; see L</"Installing is two calls, and the engine enforces it"> for
why it is not defaulted.

Options:

=over

=item * C<privileges> - ArrayRef of privilege HashRefs from L</privileges>.
Required, unless C<accept_privileges> is set

=item * C<accept_privileges> - Fetch the privileges and grant them, in one
call. A blanket grant: use it where the call site is allowed to trust the
plugin, and know that it reads as consent to whatever the plugin demands

=item * C<name> - Local name for the installed plugin, if it should differ
from C<remote>. A digest is not allowed here

=item * C<auth> - Registry credentials, as for L</privileges>

=item * C<on_event> - CodeRef called with each progress event as it arrives,
instead of the ArrayRef being collected and returned; see below

=back

Returns an ArrayRef of progress events, one per object in the engine's
newline-delimited JSON stream, C<[]> when the engine sent no progress
at all.

=head2 Progress as it arrives

Without a callback the whole stream is read before anything is parsed, so
pulling a plugin is silence until it is done. Pass C<on_event> and the events
are handed over as the daemon sends them:

    my $summary = $plugins->install('vieux/sshfs:latest',
        privileges => $privileges,
        on_event   => sub {
            my ($event, $stop) = @_;
            print $event->{status}, "\n" if defined $event->{status};
        },
    );

    $summary;   # { delivered => 18, stopped => 0 }

With a callback the return value is that summary HashRef, not the events:
C<delivered> is how many went to the callback, C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated.
See L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

The C<errorDetail> check runs on this path too, per event rather than over the
finished list, so a failure inside the 200 stream still croaks with an
L<API::Docker::Error::Stream> -- at the event that reports it, and carrying
that one event alone rather than the whole stream. It is the difference
L<API::Docker::API::Images/"A failed build still croaks, one event earlier">
describes, and it applies here identically. A caller that wants the progress
that preceded a failure must collect it in the callback.

L</upgrade> and L</push> take C<on_event> on the same terms.

A failed install croaks by one of two routes, exactly as
L<API::Docker::API::Images/pull> does, because the daemon commits to HTTP 200
the moment it flushes the first progress object. A failure before that point
arrives as a real error status -- C<incorrect privileges> is reported this
way, since it is decided before anything is pulled -- and one after it
arrives as an C<errorDetail> object inside the 200 stream, which croaks with
an L<API::Docker::Error::Stream>. C<eval> and inspect C<$@> as a string
rather than testing for the exception class.

=head2 inspect

    my $plugin = $plugins->inspect('vieux/sshfs:latest');
    say $plugin->enabled;
    say join ', ', @{ $plugin->settings->env };

Get detailed information about an installed plugin. Returns an
L<API::Docker::Type::Plugin> -- the same class L</list> returns; see
L</"What this class returns">.

The name may carry a registry host, a repository path and a tag
(C<docker.io/vieux/sshfs:latest>) and is interpolated into the request path
as given: the daemon routes this endpoint as C<< /plugins/{name:.*}/json >>,
so the slashes and the colon must survive unescaped, and they do.

=head2 remove

    $plugins->remove('vieux/sshfs:latest');
    $plugins->remove('vieux/sshfs:latest', force => 1);

Remove an installed plugin. A plugin that is still enabled is refused unless
C<force> is set.

Options:

=over

=item * C<force> - Disable the plugin before removing it. Removing a plugin
that containers are still using will break them

=back

Returns C<undef>. The Engine API reference documents a C<Plugin> object as
the 200 response body here; the daemon writes no body at all.

=head2 enable

    $plugins->enable('vieux/sshfs:latest');
    $plugins->enable('vieux/sshfs:latest', timeout => 30);

Enable an installed plugin. Returns C<undef>.

Options:

=over

=item * C<timeout> - Seconds to wait for the plugin to come up, C<0> for no
timeout (the default)

=back

C<timeout> is B<always> sent, whether or not the caller passes it. The Engine
API reference gives it a default of C<0>, but the daemon has none: it reads
the raw query value and parses it with Go's C<strconv.Atoi>, so an absent
parameter is parsed as the empty string and the request fails with
C<strconv.Atoi: parsing "": invalid syntax> as an invalid-parameter error.
This is the one endpoint in the family where omitting an optional parameter
is fatal.

=head2 disable

    $plugins->disable('vieux/sshfs:latest');
    $plugins->disable('vieux/sshfs:latest', force => 1);

Disable an enabled plugin. Returns C<undef>.

Options:

=over

=item * C<force> - Disable even while the plugin is in use. Mounts held by
the plugin stay behind, which is what makes a later L</remove> fail

=back

=head2 upgrade

    my $privileges = $plugins->privileges('vieux/sshfs:latest');
    $plugins->upgrade('vieux/sshfs:latest', privileges => $privileges);

    # upgrade a locally renamed plugin from its upstream reference
    $plugins->upgrade('sshfs', remote => 'vieux/sshfs:v2',
        accept_privileges => 1);

Upgrade an installed plugin in place. The plugin must be disabled first.

Like L</install> this carries the privilege list in its body and the daemon
checks it against what the new version demands, so C<privileges> is required
here too -- an upgrade is where a plugin's demands can B<change>, which is
the case worth looking at.

Options:

=over

=item * C<privileges> - ArrayRef of privilege HashRefs. Required, unless
C<accept_privileges> is set

=item * C<accept_privileges> - Fetch the privileges for C<remote> and grant
them, in one call

=item * C<remote> - Remote reference to upgrade to. Defaults to C<$name>,
which is what you want unless the plugin was installed under a local name

=item * C<auth> - Registry credentials, as for L</privileges>

=item * C<on_event> - CodeRef called with each progress event as it arrives.
The return value is then the summary HashRef; see
L</"Progress as it arrives">

=back

Returns an ArrayRef of progress events, C<[]> when the engine sent no
progress. Failure is reported by the same two routes as L</install>.

=head2 push

    $plugins->push('myrepo/sshfs:v1', auth => {
        username      => 'me',
        password      => 'secret',
        serveraddress => 'https://index.docker.io/v1/',
    });

Push an installed plugin to a registry. B<This writes to a real registry>
under the credentials given.

Options:

=over

=item * C<auth> - Registry credentials; HashRef of C<username> / C<password> /
C<serveraddress> / C<identitytoken>, or a pre-encoded base64 string. Sent as
C<X-Registry-Auth>

=item * C<on_event> - CodeRef called with each progress event as it arrives --
layer by layer, rather than the whole upload in one silence. The return value
is then the summary HashRef; see L</"Progress as it arrives">

=back

Unlike L<API::Docker::API::Images/push>, which sends C<X-Registry-Auth> on
every call because the engine rejects an image push without it, this sends
the header only when C<auth> is given: the plugin router decodes the header
and discards a decoding failure, so an anonymous push needs no header. The
Engine API reference documents no header on this endpoint at all; the daemon
reads it.

Returns an ArrayRef of progress events, C<[]> when the engine sent no
progress. Failure is reported by the same two routes as L</install>.

C<push> shadows the Perl builtin inside this package, which is why
L<namespace::clean> is loaded. Always call it as a method.

=head2 configure

    $plugins->configure('vieux/sshfs:latest', ['DEBUG=1']);
    $plugins->configure('vieux/sshfs:latest', 'DEBUG=1', 'sshkey.source=/tmp');

Set a plugin's user-configurable settings (C<< POST /plugins/{name}/set >>).
The plugin must be disabled. Returns C<undef>.

Settings are C<KEY=value> strings, given either as one ArrayRef or as a plain
list. They name the mutable fields of the plugin's config -- the environment
variables, mount sources, devices and args that C<< $plugin->settings >>
reports; L</inspect> is how you find out which ones a given plugin has.

The engine replaces nothing it is not told about, and rejects a key the
plugin's config does not declare as mutable.

    $plugins->configure('vieux/sshfs:latest', ['DEBUG=1']);
    $plugins->configure('vieux/sshfs:latest', 'DEBUG=1');

Both forms mean the same call, and this method takes no options in either:
anything after the ArrayRef croaks rather than being read as a setting or
quietly dropped. To bound the request, clone the resource class --
C<< $docker->plugins->using(read_timeout => 5)->configure(...) >>, see
L<API::Docker::Role::Using>.

=head1 SEE ALSO

=over

=item * L<API::Docker::Role::Entity::Plugin> - the convenience methods the
returned objects carry

=item * L<API::Docker::Type::Plugin> - the fields L</list> and L</inspect>
return

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Role::RegistryAuth> - the C<X-Registry-Auth>
encoding used here, shared with the other registry-facing endpoints

=item * L<API::Docker::API::Images> - Image endpoints, whose C<push>
sends that header on every call rather than only when credentials were
given

=item * L<API::Docker::Error::Stream> - Raised for a failure reported inside
a 200 event stream by L</install>, L</upgrade> and L</push>

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
