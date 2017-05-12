package Catalyst::Action::REST;
$Catalyst::Action::REST::VERSION = '1.20';
use utf8;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use Class::Inspector;
use Catalyst::Request::REST;
use Catalyst::Controller::REST;

BEGIN { require 5.008001; }

sub BUILDARGS {
    my $class  = shift;
    my $config = shift;
    Catalyst::Request::REST->_insert_self_into( $config->{class} );
    return $class->SUPER::BUILDARGS($config, @_);
}

=encoding utf-8

=head1 NAME

Catalyst::Action::REST - Automated REST Method Dispatching

=head1 SYNOPSIS

    sub foo :Local :ActionClass('REST') {
      ... do setup for HTTP method specific handlers ...
    }

    sub foo_GET {
      ... do something for GET requests ...
    }

    # alternatively use an Action
    sub foo_PUT : Action {
      ... do something for PUT requests ...
    }

=head1 DESCRIPTION

This Action handles doing automatic method dispatching for REST requests.  It
takes a normal Catalyst action, and changes the dispatch to append an
underscore and method name.  First it will try dispatching to an action with
the generated name, and failing that it will try to dispatch to a regular
method.

For example, in the synopsis above, calling GET on "/foo" would result in
the foo_GET method being dispatched.

If a method is requested that is not implemented, this action will
return a status 405 (Method Not Found).  It will populate the "Allow" header
with the list of implemented request methods.  You can override this behavior
by implementing a custom 405 handler like so:

   sub foo_not_implemented {
      ... handle not implemented methods ...
   }

If you do not provide an _OPTIONS subroutine, we will automatically respond
with a 200 OK.  The "Allow" header will be populated with the list of
implemented request methods. If you do not provide an _HEAD either, we will
auto dispatch to the _GET one in case it exists.

It is likely that you really want to look at L<Catalyst::Controller::REST>,
which brings this class together with automatic Serialization of requests
and responses.

When you use this module, it adds the L<Catalyst::TraitFor::Request::REST>
role to your request class.

=head1 METHODS

=over 4

=item dispatch

This method overrides the default dispatch mechanism to the re-dispatching
mechanism described above.

=cut

sub dispatch {
    my $self = shift;
    my $c    = shift;

    my $rest_method = $self->name . "_" . uc( $c->request->method );

    return $self->_dispatch_rest_method( $c, $rest_method );
}

sub _dispatch_rest_method {
    my $self        = shift;
    my $c           = shift;
    my $rest_method = shift;
    my $req         = $c->request;

    my $controller = $c->component( $self->class );

    my ($code, $name);

    # Execute normal 'foo' action.
    $c->execute( $self->class, $self, @{ $req->args } );

    # Common case, for foo_GET etc
    if ( $code = $controller->action_for($rest_method) ) {
        return $c->forward( $code,  $req->args ); # Forward to foo_GET if it's an action
    }
    elsif ($code = $controller->can($rest_method)) {
        $name = $rest_method; # Stash name and code to run 'foo_GET' like an action below.
    }

    # Generic handling for foo_*
    if (!$code) {
        my $code_action = {
            OPTIONS => sub {
                $name = $rest_method;
                $code = sub { $self->_return_options($self->name, @_) };
            },
            HEAD => sub {
              $rest_method =~ s{_HEAD$}{_GET}i;
              $self->_dispatch_rest_method($c, $rest_method);
            },
            default => sub {
                # Otherwise, not implemented.
                $name = $self->name . "_not_implemented";
                $code = $controller->can($name) # User method
                    # Generic not implemented
                    || sub { $self->_return_not_implemented($self->name, @_) };
            },
        };
        my ( $http_method, $action_name ) = ( $rest_method, $self->name );
        $http_method =~ s{\Q$action_name\E\_}{};
        my $respond = ($code_action->{$http_method}
                       || $code_action->{'default'})->();
        return $respond unless $name;
    }

    # localise stuff so we can dispatch the action 'as normal, but get
    # different stats shown, and different code run.
    # Also get the full path for the action, and make it look like a forward
    local $self->{code} = $code;
    my @name = split m{/}, $self->reverse;
    $name[-1] = $name;
    local $self->{reverse} = "-> " . join('/', @name);

    $c->execute( $self->class, $self, @{ $req->args } );
}

sub get_allowed_methods {
    my ( $self, $controller, $c, $name ) = @_;
    my $class = ref($controller) ? ref($controller) : $controller;
    my $methods = {
      map { /^$name\_(.+)$/ ? ( $1 => 1 ) : () }
        @{ Class::Inspector->methods($class) }
    };
    $methods->{'HEAD'} = 1 if $methods->{'GET'};
    delete $methods->{'not_implemented'};
    return sort keys %$methods;
};

sub _return_options {
    my ( $self, $method_name, $controller, $c) = @_;
    my @allowed = $self->get_allowed_methods($controller, $c, $method_name);
    $c->response->content_type('text/plain');
    $c->response->status(200);
    $c->response->header( 'Allow' => \@allowed );
    $c->response->body(q{});
}

sub _return_not_implemented {
    my ( $self, $method_name, $controller, $c ) = @_;

    my @allowed = $self->get_allowed_methods($controller, $c, $method_name);
    $c->response->content_type('text/plain');
    $c->response->status(405);
    $c->response->header( 'Allow' => \@allowed );
    $c->response->body( "Method "
          . $c->request->method
          . " not implemented for "
          . $c->uri_for( $method_name ) );
}

__PACKAGE__->meta->make_immutable;

1;

=back

=head1 SEE ALSO

You likely want to look at L<Catalyst::Controller::REST>, which implements a
sensible set of defaults for a controller doing REST.

This class automatically adds the L<Catalyst::TraitFor::Request::REST> role to
your request class.  If you're writing a web application which provides RESTful
responses and still needs to accommodate web browsers, you may prefer to use
L<Catalyst::TraitFor::Request::REST::ForBrowsers> instead.

L<Catalyst::Action::Serialize>, L<Catalyst::Action::Deserialize>

=head1 TROUBLESHOOTING

=over 4

=item Q: I'm getting a "415 Unsupported Media Type" error. What gives?!

A:  Most likely, you haven't set Content-type equal to "application/json", or
one of the accepted return formats.  You can do this by setting it in your query
accepted return formats.  You can do this by setting it in your query string
thusly: C<< ?content-type=application%2Fjson (where %2F == / uri escaped). >>

B<NOTE> Apache will refuse %2F unless configured otherwise.
Make sure C<AllowEncodedSlashes On> is in your httpd.conf file in order
for this to run smoothly.

=back

=head1 AUTHOR

Adam Jacob E<lt>adam@stalecoffee.orgE<gt>, with lots of help from mst and jrockway

Marchex, Inc. paid me while I developed this module. (L<http://www.marchex.com>)

=head1 CONTRIBUTORS

Tomas Doran (t0m) E<lt>bobtfish@bobtfish.netE<gt>

John Goulah

Christopher Laco

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

Hans Dieter Pearcey

Brian Phillips E<lt>bphillips@cpan.orgE<gt>

Dave Rolsky E<lt>autarch@urth.orgE<gt>

Luke Saunders

Arthur Axel "fREW" Schmidt E<lt>frioux@gmail.comE<gt>

J. Shirley E<lt>jshirley@gmail.comE<gt>

Gavin Henry E<lt>ghenry@surevoip.co.ukE<gt>

Gerv http://www.gerv.net/

Colin Newell <colin@opusvl.com>

Wallace Reis E<lt>wreis@cpan.orgE<gt>

André Walker (andrewalker) <andre@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2015 the above named AUTHOR and CONTRIBUTORS

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

