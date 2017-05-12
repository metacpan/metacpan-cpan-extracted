#line 1
package Catalyst::Test;

use strict;
use warnings;
use Test::More ();

use Catalyst::Exception;
use Catalyst::Utils;
use Class::MOP;
use Sub::Exporter;

my $build_exports = sub {
    my ($self, $meth, $args, $defaults) = @_;

    my $request;
    my $class = $args->{class};

    if ( $ENV{CATALYST_SERVER} ) {
        $request = sub { remote_request(@_) };
    } elsif (! $class) {
        $request = sub { Catalyst::Exception->throw("Must specify a test app: use Catalyst::Test 'TestApp'") };
    } else {
        unless (Class::MOP::is_class_loaded($class)) {
            Class::MOP::load_class($class);
        }
        $class->import;

        $request = sub { local_request( $class, @_ ) };
    }

    my $get = sub { $request->(@_)->content };

    my $ctx_request = sub {
        my $me = ref $self || $self;

        ### throw an exception if ctx_request is being used against a remote
        ### server
        Catalyst::Exception->throw("$me only works with local requests, not remote")
            if $ENV{CATALYST_SERVER};

        ### check explicitly for the class here, or the Cat->meta call will blow
        ### up in our face
        Catalyst::Exception->throw("Must specify a test app: use Catalyst::Test 'TestApp'") unless $class;

        ### place holder for $c after the request finishes; reset every time
        ### requests are done.
        my $c;

        ### hook into 'dispatch' -- the function gets called after all plugins
        ### have done their work, and it's an easy place to capture $c.

        my $meta = Class::MOP::get_metaclass_by_name($class);
        $meta->make_mutable;
        $meta->add_after_method_modifier( "dispatch", sub {
            $c = shift;
        });
        $meta->make_immutable( replace_constructor => 1 );
        Class::C3::reinitialize(); # Fixes RT#46459, I've failed to write a test for how/why, but it does.
        ### do the request; C::T::request will know about the class name, and
        ### we've already stopped it from doing remote requests above.
        my $res = $request->( @_ );

        ### return both values
        return ( $res, $c );
    };

    return {
        request      => $request,
        get          => $get,
        ctx_request  => $ctx_request,
        content_like => sub {
            my $action = shift;
            return Test::More->builder->like($get->($action),@_);
        },
        action_ok => sub {
            my $action = shift;
            return Test::More->builder->ok($request->($action)->is_success, @_);
        },
        action_redirect => sub {
            my $action = shift;
            return Test::More->builder->ok($request->($action)->is_redirect,@_);
        },
        action_notfound => sub {
            my $action = shift;
            return Test::More->builder->is_eq($request->($action)->code,404,@_);
        },
        contenttype_is => sub {
            my $action = shift;
            my $res = $request->($action);
            return Test::More->builder->is_eq(scalar($res->content_type),@_);
        },
    };
};

our $default_host;

{
    my $import = Sub::Exporter::build_exporter({
        groups => [ all => $build_exports ],
        into_level => 1,
    });


    sub import {
        my ($self, $class, $opts) = @_;
        Carp::carp(
qq{Importing Catalyst::Test without an application name is deprecated:\n
Instead of saying: use Catalyst::Test;
say: use Catalyst::Test (); # If you don't want to import a test app right now.
or say: use Catalyst::Test 'MyApp'; # If you do want to import a test app.\n\n})
        unless $class;
        $import->($self, '-all' => { class => $class });
        $opts = {} unless ref $opts eq 'HASH';
        $default_host = $opts->{default_host} if exists $opts->{default_host};
        return 1;
    }
}

#line 224

sub local_request {
    my $class = shift;

    require HTTP::Request::AsCGI;

    my $request = Catalyst::Utils::request( shift(@_) );
    _customize_request($request, @_);
    my $cgi     = HTTP::Request::AsCGI->new( $request, %ENV )->setup;

    $class->handle_request( env => \%ENV );

    my $response = $cgi->restore->response;
    $response->request( $request );
    return $response;
}

my $agent;

#line 248

sub remote_request {

    require LWP::UserAgent;

    my $request = Catalyst::Utils::request( shift(@_) );
    my $server  = URI->new( $ENV{CATALYST_SERVER} );

    _customize_request($request, @_);

    if ( $server->path =~ m|^(.+)?/$| ) {
        my $path = $1;
        $server->path("$path") if $path;    # need to be quoted
    }

    # the request path needs to be sanitised if $server is using a
    # non-root path due to potential overlap between request path and
    # response path.
    if ($server->path) {
        # If request path is '/', we have to add a trailing slash to the
        # final request URI
        my $add_trailing = $request->uri->path eq '/';

        my @sp = split '/', $server->path;
        my @rp = split '/', $request->uri->path;
        shift @sp;shift @rp; # leading /
        if (@rp) {
            foreach my $sp (@sp) {
                $sp eq $rp[0] ? shift @rp : last
            }
        }
        $request->uri->path(join '/', @rp);

        if ( $add_trailing ) {
            $request->uri->path( $request->uri->path . '/' );
        }
    }

    $request->uri->scheme( $server->scheme );
    $request->uri->host( $server->host );
    $request->uri->port( $server->port );
    $request->uri->path( $server->path . $request->uri->path );

    unless ($agent) {

        $agent = LWP::UserAgent->new(
            keep_alive   => 1,
            max_redirect => 0,
            timeout      => 60,

            # work around newer LWP max_redirect 0 bug
            # http://rt.cpan.org/Ticket/Display.html?id=40260
            requests_redirectable => [],
        );

        $agent->env_proxy;
    }

    return $agent->request($request);
}

sub _customize_request {
    my $request = shift;
    my $opts = pop(@_) || {};
    $opts = {} unless ref($opts) eq 'HASH';
    if ( my $host = exists $opts->{host} ? $opts->{host} : $default_host  ) {
        $request->header( 'Host' => $host );
    }
}

#line 353

1;
