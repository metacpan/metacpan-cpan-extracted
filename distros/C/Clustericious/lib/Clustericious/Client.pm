package Clustericious::Client;

use strict;
use warnings;
use 5.010;
use Mojo::Base qw/-base/;
use Mojo::UserAgent;
use Mojo::ByteStream qw/b/;
use Mojo::Parameters;
use Clustericious;
use Clustericious::Config;
use Clustericious::Client::Object;
use Clustericious::Client::Meta;
use Clustericious::Client::Meta::Route;
use MojoX::Log::Log4perl;
use Log::Log4perl qw/:easy/;
use File::Temp;
use JSON::MaybeXS qw( encode_json decode_json );
use Carp qw( carp );
use Mojo::Util qw( monkey_patch );

# ABSTRACT: Construct command line and perl clients for RESTful services.
our $VERSION = '1.26'; # VERSION


has server_url => '';
has [qw(tx res userinfo ua )];
has _remote => ''; # Access via remote()
has _cache => sub { + {} }; # cache of credentials

sub client
{
  carp "Clustericious::Client->client is deprecated (use ua instead)";
  shift->ua(@_);
}

sub import
{
  my($class) = @_;
  my $caller = caller;

  monkey_patch $caller, route => \&route;
  monkey_patch $caller, route_meta => \&route_meta;
  monkey_patch $caller, route_args => \&route_args;
  monkey_patch $caller, route_doc => sub {
    Clustericious::Client::Meta->add_route( $caller, @_ );
  };
  monkey_patch $caller, object => \&object;
  monkey_patch $caller, import => sub {};

  do {
    no strict 'refs';
    push @{"${caller}::ISA"}, $class unless $caller->isa($class);
  };
}


sub _mojo_user_agent_factory
{
  my($class, $new) = @_;
  state $factory = sub { Mojo::UserAgent->new };
  $factory = $new if $new;
  defined wantarray ? $factory->() : ();
}

sub new
{
  my($class, %args) = @_;

  my $config = delete $args{config};
  
  my $self = $class->SUPER::new(%args);

  $self->{_base_config} = $config if $config;

  if($self->{app})
  {
    my $app = $self->{app};
    $app = $app->new() unless ref($app);
    my $ua = $self->_mojo_user_agent_factory();
    return undef unless $ua;
    eval { $ua->server->app($app) } // $ua->app($app);
    $self->ua($ua);
  }
  else
  {
    $self->ua($self->_mojo_user_agent_factory());
    unless(length $self->server_url)
    {
      my $url = $self->config->url;
      $url =~ s{/$}{};
      $self->server_url($url);
    }
  }

  my $ua = $self->ua;
  $ua->transactor->name($self->user_agent_string);
  $ua->inactivity_timeout($ENV{CLUSTERICIOUS_KEEP_ALIVE_TIMEOUT} || 300);

  if(eval { require Clustericious::Client::Local; })
  {
    Clustericious::Client::Local->local($self);
  }

  $self;
}



sub remote {
    my $self = shift;
    return $self->_remote unless @_ > 0;
    my $remote = shift;
    unless ($remote) { # reset to default
        $self->{_remote} = '';
        $self->server_url($self->config->url);
        return;
    }
    my $info = $self->_base_config->remotes->$remote;
    TRACE "Using remote url : ".$info->{url};
    $self->server_url($info->{url});
    $self->userinfo('');
    $self->_remote($remote);
}


sub remotes {
    my $self = shift;
    my %found = $self->_base_config->remotes(default => {});
    return keys %found;
}


sub login {
    my $self = shift;
    my %args = @_;
    my ($user,$pw) =
           @_==2 ? @_
         : @_    ?  @args{qw/username password/}
         : map $self->config->$_, qw/username password/;
    $self->userinfo(join ':', $user,$pw);
}


sub errorstring {
    my $self = shift;
    WARN "Missing response in ua object" unless $self->res;
    return unless $self->res;
    return if $self->res->code && $self->res->is_success;
    my $error = $self->res->error;
    if(defined $error->{advice})
    {
        return sprintf("[%d] %s", $error->{advice}, $error->{message});
    }
    elsif(defined $error->{code})
    {
        return sprintf( "(%d) %s", $error->{code}, $error->{message});
    }
    else
    {
        return $error->{message} // '';
    }
}


sub has_error {
    my $c = shift;
    return unless $c->tx || $c->res;
    return 1 if $c->tx && $c->tx->error;
    return 1 if $c->res && !$c->res->is_success;
    return 0;
}


sub user_agent_string {
    my($self) = @_;
    my $class = ref($self);
    my $version1 = $Clustericious::Client::VERSION // 'dev';
    my $version2 = do {
      no strict 'refs';
      ${"${class}::VERSION"};
    } // 'dev';
    "Clustericious::Client/$version1 $class/$version2";
}


sub route {
    my $subname = shift;
    my $objclass = ref $_[0] eq 'ARRAY' ? shift->[0] : undef;
    my $doc      = ref $_[-1] eq 'SCALAR' ? ${ pop() } : "";
    my $url      = pop || "/$subname";
    my $method   = shift || 'GET';

    my $client_class = scalar caller();
    my $meta = Clustericious::Client::Meta::Route->new(
            client_class => scalar caller(),
            route_name => $subname
    );

    $meta->set(method => $method);
    $meta->set(url    => $url);
    $meta->set_doc($doc);

    if ($objclass) {
        eval "require $objclass";
        if ($@) {
            LOGDIE "Error loading $objclass : $@" unless $@ =~ /Can't locate/i;
        }
    }

    {
        no strict 'refs';
        *{caller() . "::$subname"} = sub {
            my $self = shift;
            my @args = $self->meta_for($subname)->process_args(@_);
            my $got = $self->_doit($meta,$method,$url,@args);
            return $objclass->new($got, $self) if $objclass;
            return $got;
        };
    }

}


sub route_meta {
    my $name = shift;
    my $attrs = shift;
    my $meta = Clustericious::Client::Meta::Route->new(
        client_class => scalar caller(),
        route_name   => $name
    );

    $meta->set($_ => $attrs->{$_}) for keys %$attrs;
}


sub route_args {
    my $name = shift;
    my $args = shift;
    die "args must be an array ref" unless ref $args eq 'ARRAY';
    my $meta = Clustericious::Client::Meta::Route->new(
        client_class => scalar caller(),
        route_name   => $name
    );

    $meta->set(args => $args);
}


sub object {
    my $objname = shift;
    my $url     = shift || "/$objname";
    my $doc     = ref $_[-1] eq 'SCALAR' ? ${ pop() } : '';
    my $caller  = caller;

    my $objclass = "${caller}::" .
        join('', map { ucfirst } split('_', $objname)); # foo_bar => FooBar

    eval "require $objclass";
    if ($@) {
        LOGDIE "Error loading $objclass : $@" unless $@ =~ /Can't locate/i;
    }

    $objclass = 'Clustericious::Client::Object' unless $objclass->can('new');

    Clustericious::Client::Meta->add_object(scalar caller(),$objname,$doc);

    no strict 'refs';
    *{"${caller}::$objname"} = sub {
        my $self = shift;
        my $meta = Clustericious::Client::Meta::Route->new(
            client_class => $caller,
            route_name   => $objname
        );
        $meta->set( quiet_post => 1 );
        my $data = $self->_doit( $meta, GET => $url, @_ );
        $objclass->new( $data, $self );
    };
    *{"${caller}::${objname}_delete"} = sub {
        my $meta = Clustericious::Client::Meta::Route->new(
            client_class => $caller,
            route_name   => $objname.'_delete',
        );
        $meta->set(dont_read_files => 1);
        shift->_doit( $meta, DELETE => $url, @_ );
    };
    *{"${caller}::${objname}_search"} = sub {
        my $meta = Clustericious::Client::Meta::Route->new(
            client_class => $caller,
            route_name   => $objname.'_search'
        );
        $meta->set(dont_read_files => 1);
        shift->_doit( $meta, POST => "$url/search", @_ );
    };
}

sub _doit {
    my $self = shift;
    my $meta;
    $meta = shift if ref $_[0] eq 'Clustericious::Client::Meta::Route';
    my ($method, $url, @args) = @_;

    my $auto_failover;
    $auto_failover = 1 if $meta && $meta->get('auto_failover');

    $url = $self->server_url . $url if $self->server_url && $url !~ /^http/;
    return undef if $self->server_url eq 'http://0.0.0.0';

    my $cb;
    my $body = '';
    my $headers = {};

    if ($method eq 'POST' && grep /^--/, @args) {
        s/^--// for @args;
        @args = ( { @args } );
    }

    $url = Mojo::URL->new($url) unless ref $url;
    my $parameters = $url->query;

    # Set up mappings from parameter names to modifier callbacks.
    my %url_modifier;
    my %payload_modifer;
    my %gen_url_modifier = (
        query  => sub { my $name = shift;
            sub { my ($u,$v) = @_; $u->query({$name => $v}) }  },
        append => sub { my $name = shift;
            sub { my ($u,$v) = @_; push @{ $u->path->parts } , $v; $u; } },
    );
    my %gen_payload_modifier = (
        array => sub {
            my ( $name, $key ) = @_;
            LOGDIE "missing key for array payload modifier" unless $key;
            sub { my $body = shift; $body ||= {}; push @{ $body->{$key} }, ( $name => shift ); $body; }
        },
        hash => sub {
            my $name = shift;
            sub { my $body = shift; $body ||= {}; $body->{$name} = shift; $body; }
        },
    );
    if ($meta && (my $arg_spec = $meta->get('args'))) {
        for (@$arg_spec) {
            my $name = $_->{name};
            if (my $modifies_url = $_->{modifies_url}) {
                $url_modifier{$name} =
                    ref($modifies_url) eq 'CODE'            ? $modifies_url
                 :  ($a = $gen_url_modifier{$modifies_url}) ? $a->($name)
                 :  die "don't understand how to interpret modifies_url=$modifies_url";
            }
            if (my $modifies_payload = $_->{modifies_payload}) {
                 $payload_modifer{$name} =
                    ref($modifies_payload) eq 'CODE' ? $modifies_payload
                 : ($a = $gen_payload_modifier{$modifies_payload}) ? $a->($name,$_->{key})
                 : LOGDIE "don't understand how to interpret modifies_payload=$modifies_payload";
            }
        }
    }

    while (defined(my $arg = shift @args)) {
        if (ref $arg eq 'HASH') {
            $method = 'POST';
            $parameters->append(skip_existing => 1) if $meta && $meta->get("skip_existing");
            $body = encode_json $arg;
            $headers = { 'Content-Type' => 'application/json' };
        } elsif (ref $arg eq 'CODE') {
            $cb = $self->_mycallback($arg);
        } elsif (my $code = $url_modifier{$arg}) {
            $url = $code->($url, shift @args);
        } elsif (my $code2 = $payload_modifer{$arg}) {
            $body = $code2->($body, shift @args);
        } elsif ($method eq "GET" && $arg =~ s/^--//) {
            my $value = shift @args;
            $parameters->append($arg => $value);
        } elsif ($method eq "GET" && $arg =~ s/^-//) {
            # example: $client->esdt(-range => [1 => 100]);
            my $value = shift @args;
            if (ref $value eq 'ARRAY') {
                $value = "items=$value->[0]-$value->[1]";
            }
            $headers->{$arg} = $value;
        } elsif ($method eq "POST" && !ref $arg) {
            $body = $arg;
            $headers = shift @args if $args[0] && ref $args[0] eq 'HASH';
        } else {
            push @{ $url->path->parts }, $arg;
        }
    }
    $url = $url->to_abs unless $url->is_abs || $self->{app};
    WARN "url $url is not absolute" unless $url =~ /^http/i;

    $url->userinfo($self->userinfo) if $self->userinfo;

    DEBUG ( (ref $self)." : $method " ._sanitize_url($url));
    $headers->{Connection} ||= 'Close';
    $headers->{Accept}     ||= 'application/json';

    if($body && ref $body eq 'HASH' || ref $body eq 'ARRAY')
    {
        $headers->{'Content-Type'} = 'application/json';
        $body = encode_json $body;
    }

    return $self->ua->build_tx($method, $url, $headers, $body, $cb) if $cb;

    my $tx = $self->ua->build_tx($method, $url, $headers, $body);

    $tx = $self->ua->start($tx);
    my $res = $tx->res;
    $self->res($res);
    $self->tx($tx);

    my $auth_header;
    if (($tx->res->code||0) == 401 && ($auth_header = $tx->res->headers->www_authenticate)
        && !$url->userinfo && ($self->_has_auth || $self->_can_auth)) {
        DEBUG "received code 401, trying again with credentials";
        my ($realm) = $auth_header =~ /realm=(.*)$/i;
        my $host = $url->host;
        $self->login( $self->_has_auth ? () : $self->_get_user_pw($host,$realm) );
        return $self->_doit($meta ? $meta : (), @_);
    }

    if ($res->is_success) {
        TRACE "Got response : ".$res->to_string;
        my $content_type = $res->headers->content_type || do {
            WARN "No content-type from "._sanitize_url($url);
            "text/plain";
        };
        return $method =~ /HEAD|DELETE/       ? 1
            : $content_type =~ qr[application/json] ? decode_json($res->body)
            : $res->body;
    }

    # Failed.
    my $err = $tx->error;
    my ($msg, $code) = ($err->{message}, $err->{code});
    $msg ||= 'unknown error';
    my $s_url = _sanitize_url($url);

    if ($code) {
        if ($code == 404) {
            TRACE "$method $url : $code $msg"
                 unless $ENV{ACPS_SUPPRESS_404}
                     && $url =~ /$ENV{ACPS_SUPPRESS_404}/;
        } else {
            ERROR "Error trying to $method $s_url : $code $msg";
            TRACE "Full error body : ".$res->body if $res->body;
            my $brief = $res->body || '';
            $brief =~ s/\n/ /g;
            ERROR substr($brief,0,200) if $brief;
        }
        # No failover for legitimate status codes.
        return undef;
    }

    unless ($auto_failover) {
        ERROR "Error trying to $method $s_url : $msg";
        ERROR $res->body if $res->body;
        return undef;
    }
    my $failover_urls = $self->config->failover_urls(default => []);
    unless (@$failover_urls) {
        ERROR $msg;
        return undef;
    }
    INFO "$msg but will try up to ".@$failover_urls." failover urls";
    TRACE "Failover urls : @$failover_urls";
    for my $url (@$failover_urls) {
        DEBUG "Trying $url";
        $self->server_url($url);
        my $got = $self->_doit(@_);
        return $got if $got;
    }

    return undef;
}

sub _mycallback
{
    my $self = shift;
    my $cb = shift;
    sub
    {
        my ($ua, $tx) = @_;

        $self->res($tx->res);
        $self->tx($tx);

        if ($tx->res->is_success)
        {
            my $body = $tx->res->headers->content_type =~ qr[application/json]
                ? decode_json($tx->res->body) : $tx->res->body;

            $cb->($body ? $body : 1);
        }
        else
        {
            $cb->();
        }
    }
}

sub _sanitize_url {
    # Remove passwords from urls for displaying
    my $url = shift;
    $url = Mojo::URL->new($url) unless ref $url eq "Mojo::URL";
    return $url unless $url->userinfo;
    my $c = $url->clone;
    $c->userinfo("user:*****");
    $c;
}

sub _appname
{
  my($self) = @_;
  (my $appname = ref $self) =~ s/:.*$//;
  $appname;
}


sub config
{
  my($self) = @_;  
  my $conf = $self->_base_config;
  if (my $remote = $self->_remote)
  {
    return $conf->remotes->$remote;
  }
  $conf;
}

sub _config
{
  carp "Clustericious::Client->_config has been deprecated use config instead";
  shift->config(@_);
}

sub _base_config
{
  # Independent of remotes
  my($self) = @_;
  unless(defined $self->{_base_config})
  {
    my $config_name = ref $self;
    $config_name =~ s/::Client$//;
    $config_name =~ s/::/-/;
    $self->{_base_config} = Clustericious::Config->new($config_name);
    $self->{_base_config}->{url} //= Clustericious->_default_url($config_name);
  }
  
  $self->{_base_config};
}

sub _has_auth
{
  my($self) = @_;
  my $config = $self->config;
  $config->username(default => '') && password(default => '') ? 1 : 0;
}

sub _can_auth
{
  my $self = shift;
  -t STDIN ? 1 : 0;
}

sub _get_user_pw  {
    my $self = shift;
    my $host = shift;
    my $realm = shift;
    $realm = '' unless defined $realm;
    return @{ $self->_cache->{$host}{$realm} } if exists($self->_cache->{$host}{$realm});
    # "use"ing causes too many warnings; load on demand.
    require Term::Prompt;
    my $user = Term::Prompt::prompt('x', "Username for $realm at $host : ", '', $ENV{USER} // $ENV{USERNAME});
    my $pw = Term::Prompt::prompt('p', 'Password:', '', '');
    $self->_cache->{$host}{$realm} = [ $user, $pw ];
    return ($user,$pw);
}


sub meta_for {
    my $self = shift;
    my $route_name = shift || [ caller 1 ]->[3];
    if ( $route_name =~ /::([^:]+)$/ ){
        $route_name = $1;
    }
    my $meta = Clustericious::Client::Meta::Route->new(
        route_name   => $route_name,
        client_class => ref $self
    );
}


sub version {
    my $self = shift;
    my $meta = $self->meta_for("version");
    $meta->set(auto_failover => 1);
    $self->_doit($meta, GET => '/version');
}


sub status {
    my $self = shift;
    my $meta = $self->meta_for("status");
    $meta->set(auto_failover => 0);
    $self->_doit($meta, GET => '/status');
}


sub api {
    my $self = shift;
    my $meta = $self->meta_for("api");
    $meta->set( auto_failover => 1 );
    $self->_doit( $meta, GET => '/api' );
}


sub logtail {
    my $self = shift;
    my $got = $self->_doit(GET => '/log', @_);
    return { text => $got };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Client - Construct command line and perl clients for RESTful services.

=head1 VERSION

version 1.26

=head1 SYNOPSIS

tracks.pm :

    package Tracks;
    use Clustericious::Client;

    route 'mixes' => '/mixes.json';
    route_doc mixes => 'Get a list of mixes.';
    route_args mixes => [
        { name => 'api_key', type => '=s', modifies_url => "query", required => 1 },
        { name => 'per_page',type => '=i', modifies_url => "query", },
        { name => 'tags',    type => '=s', modifies_url => "query" },
    ];
    # a 'mixes' method will be constructed automatically.
    # a 'mixes' command line parameter will be recognized automatically.

    route 'play' => '/play.json';
    route_args play => [
        { name => 'token', type => '=s', modifies_url => 'query', required => 1 }
    ];
    sub play {
        my $c = shift;
        my %args = $c->meta_for->process_args(@_);
        # do something with $args{token}
    }
    # A 'play' command line parameter will call the above method.

tracks.pl :

    use lib '.';
    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($TRACE);
    use tracks;

    my $t = Tracks->new(server_url => 'http://8tracks.com' );
    my $mixes = $t->mixes(
         tags => 'jazz',
         api_key => $api_key,
         per_page => 2,
         ) or die $t->errorstring;
    print "Mix : $_->{name}\n" for @{ $mixes->{mixes} };

tracks_cli :

    use lib '.';
    use Clustericious::Client::Command;
    use tracks;

    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($TRACE);

    Clustericious::Client::Command->run(Tracks->new, @ARGV);

~/etc/Tracks.conf :

    ---
    url : 'http://8tracks.com'

From the command line :

    $ perl tracks.pl
    $ tracks_cli mixes --api_key foo --tags jazz

=head1 DESCRIPTION

Clustericious::Client is library for construction clients for RESTful
services.  It provides a mapping between command line arguments, method
arguments, and URLs.

The builder functions add methods to the client object that translate
into basic REST functions.  All of the 'built' methods return undef on
failure of the REST/HTTP call, and auto-decode the returned body into
a data structure if it is application/json.

=head1 ATTRIBUTES

This class inherits from L<Mojo::Base>, and handles attributes like
that class.  The following additional attributes are used.

=head2 config

Configuration object.  Defaults to the appropriate L<Clustericious::Config>
class.

=head2 ua

User agent to process the HTTP stuff with.  Defaults to a
L<Mojo::UserAgent>.

=head2 client

Deprecated alias for L</ua> above.  Do not use in new code.  May be removed
in the future.

=head2 app

For testing, you can specify a Mojolicious app name.

=head2 server_url

You can override the URL prefix for the client, otherwise it
will look it up in the config file.

=head2 res, tx

After an HTTP error, the built methods return undef.  This function
will return the L<Mojo::Message::Response> from the server.

res->code and res->message are the returned HTTP code and message.

tx has the Mojo::Transaction::HTTP object.

=head1 METHODS

=head2 new

 my $f = Foo::Client->new();
 my $f = Foo::Client->new(server_url => 'http://someurl');
 my $f = Foo::Client->new(app => 'MyApp'); # For testing...

If the configuration file has a "url" entry, this will
be used as the default url (first case above).

=head2 userinfo

Credentials currently stored.

=head2 remote

Tell the client to use the remote information in the configuration.
For instance, if the config has

 remotes :
    test :
        url: http://foo
    bar :
        url: http://baz
        username : one
        password : two

Then setting remote("test") uses the first
url, and setting remote("bar") uses the
second one.

=head2 remotes

Return a list of available remotes.

=head2 login

Log in to the server.  This will send basic auth info
along with every subsequent request.

    $f->login; # looks for username and password in $app.conf
    $f->login("elmer", "fudd");
    $f->login(username => "elmer", password => "fudd");

=head2 errorstring

After an error, this returns an error string made up of the server
error code and message.  (use res->code and res->message to get the
parts)

(e.g. "Error: (500) Internal Server Error")

=head2 has_error

Returns true if there was a recent error.

=head2 user_agent_string

Returns the user agent string for use in HTTP transactions.
By default this includes the clustericious and service
version numbers, but you can override it to be whatever
you want.

=head1 FUNCTIONS

=head2 route

 route 'subname';                    # GET /subname
 route subname => '/url';            # GET /url
 route subname => GET => '/url';     # GET /url
 route subname => POST => '/url';    # POST /url
 route subname => DELETE => '/url';  # DELETE /url
 route subname => ['SomeObjectClass'];
 route subname \"<documentation> <for> <some> <args>";
 route_args subname => [ { name => 'param', type => "=s", modifies_url => 'query' } ]
 route_args subname => [ { name => 'param', type => "=i", modifies_url => 'append' } ]

Makes a method subname() that does the REST action.

 route subname => $url => $doc

is equivalent to

 route      subname => $url
 route_args subname => [ { name => 'all', positional => 'many', modifies_url => 'append' } ];
 route_doc  subname => $$doc

with the additional differences that GET becomes a POST if the argument is
a hashref, and heuristics are used to read YAML files and STDIN.

See route_args and route_doc below.

=head2 route_meta

Set metadata attributes for this route.

    route_meta 'bucket_map' => { auto_failover => 1 }
    route_meta 'bucket_map' => { quiet_post => 1 }
    route_meta 'bucket_map' => { skip_existing => 1 }

=head2 route_args

Set arguments for this route.  This allows command line options
to be transformed into method arguments, and allows normalization
and validation of method arguments.  route_args associates an array
ref with the name of a route.  Each entry in the array ref is a hashref
which may have keys as shown in this example :

  route_args send => [
            {
                name     => 'what',              # name of the route
                type     => '=s',                # type (see L<Getopt::Long>)
                alt      => 'long|extra|big',    # alternative names
                required => 0,                   # Is it required?
                doc      => 'get a full status', # brief documentation
            },
            {
                name     => 'items',               # name of the route
                type     => '=s',                  # type (see L<Getopt::Long>)
                doc      => 'send a list of items' # brief docs
                preprocess => 'list'               # make an array ref from a list
            },
        ];

The keys have the following effect :

=over

=item name

The name of the option.  This should be preceded by two dashes
on the command line.  It is also sent as the named argument to the
method call.

=item type

A type, as described in L<Getopt::Long>.  This will be appended to
the name to form the option specification.

=item alt

An alternative name or names (joined by |).

=item required

If this arg is required, set this to 1.

=item doc

A brief description to be printed in error messages and help documentation.

=item preprocess

Can be either C<yamldoc>, C<list> or C<datetime>.

For yamldoc and list, the argument is expected
to refer to either a filename which exists, or else "-" for STDIN.  The contents
are then transformed from YAML (for yamldoc), or split on carriage returns (for list)
to form either a data structure or an arrayref, respectively.

For datetime the string is run through Date::Parse and turned into an ISO 8601 datetime.

=item modifies_url

Describes how the URL is affected by the arguments.  Can be
'query', 'append', or a code reference.

'query' adds to the query string, e.g.

    route subname '/url'
    route_args subname => [ { name => 'foo', type => "=s", modifies_url => 'query' } ]

This will cause this invocation :

    $foo->subname( "foo" => "bar" )

to send a GET request to /url?foo=bar.

Similarly, 'append' is equivalent to

    sub { my ($u,$v) = @_; push @{ $u->path->parts } , $v }

i.e. append the parameter to the end of the URL path.

If route_args is omitted for a route, then arguments with a '--'
are treated as part of the query string, and arguments with a '-'
are treated as HTTP headers (for a GET request).  If a hash
reference is passed, the method changes to POST and the hash is
encoded into the body as application/json.

=item modifies_payload, key

Describes how the parameter modifies the payload.

'hash' means set $body->{$name} to $value.
'array' means push ( $name => $value ) onto $body->{$key}.
   (key should also be specified)

=item positional

Can be 'one' or 'many'.

If set, this is a positional parameter, not a named parameter.  i.e.
getopt will not be used to parse the command line, and
it will be take from a list sent to the method.  For instance

  route_args name => [ { name => 'id', positional => 'one' } ];

Then

  $client->name($id)

or

 commandlineclient name id

will result in the method receiving (id => $id).

If set to 'many', multiple parameters may be sent, e.g.

    $client->name($id1, $id2,....)

=back

=head2 object

 object 'objname';                   # defaults to URL /objname
 object objname => '/some/url';

Creates two methods, one named with the supplied objname() (used for
create, retrieve, update), and one named objname_delete().

Any scalar arguments to the created functions are tacked onto the end
of the url.  Performs a GET by default, but if you pass a hash
reference, the method changes to POST and the hash is encoded into the
body as application/json.

The 'object' routes will automatically look for a class named with the
object name, but upper case first letter and first after any
underscores, which are removed:

 object 'myobj';    Foo::Client::Myobj;
 object 'my_obj';   Foo::Client::MyObj;

If such a class isn't found, object will default to returning a
L<Clustericious::Client::Object>.

=head2 meta_for

Get the metadata for a route.

    $client->meta_for('welcome');

Returns a Clustericious::Client::Meta::Route object.

=head1 COMMON ROUTES

These are routes that are automatically supported by all clients.
See L<Clustericious::Plugin::CommonRoutes>.

=head2 version

Retrieve the version on the server.

=head2 status

Retrieve the status from the server.

=head2 api

Retrieve the API from the server

=head2 logtail

Get the last N lines of the server log file.

=head1 EXAMPLES

 package Foo::Client;
 use Clustericious::Client;

 route 'welcome' => '/';                   # GET /
 route status;                             # GET /status
 route myobj => [ 'MyObject' ];            # GET /myobj
 route something => GET => '/some/';
 route remove => DELETE => '/something/';

 object 'obj';                             # Defaults to /obj
 object 'foo' => '/something/foo';         # Can override the URL

 route status => \"Get the status";        # Scalar refs are documentation
 route_doc status => "Get the status";     # or you can use route_doc
 route_args status => [                    # route_args sets method or cli arguments
            {
                name     => 'full',
                type     => '=s',
                required => 0,
                doc      => 'get a full status',
            },
        ];

 route_args wrinkle => [                   # methods correspond to "route"s
     {
         name => 'time'
     }
 ];

 sub wrinkle {                             # provides cli command as well as a method
    my $c = shift;
    my %args = @_;
    if ($args{time}) {
            ...
    }
 }

 ----------------------------------------------------------------------

 use Foo::Client;

 my $f = Foo::Client->new();
 my $f = Foo::Client->new(server_url => 'http://someurl');
 my $f = Foo::Client->new(app => 'MyApp'); # For testing...

 my $welcome = $f->welcome();              # GET /
 my $status = $f->status();                # GET /status
 my $myobj = $f->myobj('key');             # GET /myobj/key, MyObject->new()
 my $something = $f->something('this');    # GET /some/this
 $f->remove('foo');                        # DELETE /something/foo

 my $obj = $f->obj('this', 27);            # GET /obj/this/27
 # Returns either 'Foo::Client::Obj' or 'Clustericious::Client::Object'

 $f->obj({ set => 'this' });               # POST /obj
 $f->obj('this', 27, { set => 'this' });   # POST /obj/this/27
 $f->obj_delete('this', 27);               # DELETE /obj/this/27
 my $obj = $f->foo('this');                # GET /something/foo/this

 $f->status(full => "yes");
 $f->wrinkle( time => 1 ); 

 ----------------------

 #!/bin/sh
 fooclient status
 fooclient status --full yes
 fooclient wrinkle --time

=head1 SEE ALSO

L<Clustericious::Config>, L<Clustericious>, L<Mojolicious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
