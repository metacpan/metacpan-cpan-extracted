package AnyEvent::HTTPD::Router;

use common::sense;
use parent 'AnyEvent::HTTPD';

use AnyEvent::HTTPD;
use Carp;

use AnyEvent::HTTPD::Router::DefaultDispatcher;
our $VERSION = '1.0.1';

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = @_;

    # todo documentation how to overwrite your dispathing
    my $dispatcher       = delete $args{dispatcher};
    my $routes           = delete $args{routes};
    my $auto_respond_404 = delete $args{auto_respond_404};
    my $dispatcher_class = delete $args{dispatcher_class}
        || 'AnyEvent::HTTPD::Router::DefaultDispatcher';
    my $known_methods    = delete $args{known_methods}
        || [ qw/GET HEAD POST PUT PATCH DELETE TRACE OPTIONS CONNECT/ ];

    my $self = $class->SUPER::new(%args);

    $self->{known_methods} = $known_methods;
    $self->{dispatcher}    = defined $dispatcher
        ? $dispatcher
        : $dispatcher_class->new();

    $self->reg_cb(
        'request' => sub {
            my $self = shift;
            my $req  = shift;
            my $matched = $self->dispatcher->match( $self, $req );
            unless ($matched) {
                $self->event( 'no_route_found' => $req );
            }
        },
    );

    $self->reg_cb('no_route_found' => sub {
        my ( $httpd, $req ) = @_;
        $req->respond( [ 404, 'not found', {}, '' ] );
    }) if $auto_respond_404;

    if ($routes) {
        $self->reg_routes( @$routes );
    }

    return $self;
}

sub dispatcher { shift->{dispatcher} }

sub _check_verb {
    my $self    = shift;
    my $verb    = shift;
    my $methods = shift;

    if ( $verb =~ m/^:/ ) {
        $methods->{$_}++ for qw(GET POST);  # convert ':verbs' to POST and GET
        return 1;
    } elsif ( grep { $verb eq $_ } @{ $self->{known_methods} } ) {
        $methods->{$verb}++;
        return 1;
    }

    return;
}

sub reg_routes {
    my $self = shift;

    croak 'arguments to reg_routes are required' if @_ == 0;
    croak 'arguments to reg_routes are confusing' if @_ % 3 != 0;

	# * mix allowed methods and new http methods together
    my %methods = map { $_ => 1 } @{ $self->allowed_methods };

    while (my ($verbs, $path, $cb) = splice(@_, 0, 3) ) {

        $verbs = ref($verbs) eq 'ARRAY'
            ? $verbs
            : [ $verbs ];

        if ( not ref($cb) eq 'CODE' ) {
            croak 'callback must be a coderef';
        }
        elsif ( not $path =~ m/^\// ) {
            croak 'path syntax is wrong';
        }
        foreach my $verb (@$verbs) {
            croak 'verbs or methods are wrong'
                unless $self->_check_verb( $verb, \%methods );
        }

        $self->dispatcher->add_route($verbs, $path, $cb);
    }

	# set allowed methods new
	# Todo: setter doesnt work in this AE::HTTPD version
	# so must do push(@{$self->{allowed_methods}}
	# later we can do setter if AE::HTTPD version is high enough
    $self->{allowed_methods} = [ sort keys %methods ];
}

1;

__END__

=encoding utf-8

=head1 NAME

AnyEvent::HTTPD::Router - Adding Routes to AnyEvent::HTTPD

=head1 DESCRIPTION

AnyEvent::HTTPD::Router is an extension to the L<AnyEvent::HTTPD> module, from
which it is inheriting. It adds the C<reg_routes()> method to it.

This module aims to add as little as possible overhead to it while still being
flexible and extendable. It requires the same little dependencies that
L<AnyEvent::HTTPD> uses.

The dispatching for the routes happens first. If no route could be found, or you
do not stop further dispatching with C<stop_request()> the registered callbacks
will be executed as well; as if you would use L<AnyEvent::HTTPD>. In other
words, if you plan to use routes in your project you can use this module and
upgrade from callbacks to routes step by step.

Routes support http methods, but custom methods
L<https://cloud.google.com/apis/design/custom_methods> can also be used. You
don't need to, of course ;-)

=head1 SYNOPSIS

 use AnyEvent::HTTPD::Router;

 my $httpd       = AnyEvent::HTTPD::Router->new( port => 1337 );
 my $all_methods = [qw/GET DELETE HEAD POST PUT PATCH/];

 $httpd->reg_routes(
     GET => '/index.txt' => sub {
         my ( $httpd, $req ) = @_;
         $httpd->stop_request;
         $req->respond([
             200, 'ok', { 'Content-Type' => 'text/plain', }, "test!" ]);
     },
     $all_methods => '/my-method' => sub {
         my ( $httpd, $req ) = @_;
         $httpd->stop_request;
         $req->respond([
             200, 'ok', { 'X-Your-Method' => $req->method }, '' ]);
     },
     GET => '/calendar/:year/:month/:day' => sub {
         my ( $httpd, $req, $param ) = @_;
         my $calendar_entries = get_cal_entries(
             $param->{year}, $param->{month}, $param->{day}
         );

         $httpd->stop_request;
         $reg->respond([
             200, 'ok', { 'Content-Type' => 'application/json'},
             to_json($calendar_entries)
         ]);
     },
     GET => '/static-files/*' => sub {
         my ( $httpd, $req, $param ) = @_;
         my $requeted_file = $param->{'*'};
         my ($content, $content_type) = black_magic($requested_file);

         $httpd->stop_request;
         $req->respond([
             200, 'ok', { 'Content-Type' => $content_type }, $content ]);
     }
 );

 $httpd->run();

=head1 METHODS

=over

=item * C<new()>

Creates a new C<AnyEvent::HTTPD::Router> server. The constructor handles the
following parameters. All further parameters are passed to C<AnyEvent::HTTPD>.

=over

=item * C<dispatcher>

You can pass your own implementation of your router dispatcher into this module.
This expects the dispatcher to be an instance not a class name.

=item * C<dispatcher_class>

You can pass your own implementation of your router dispatcher into this module.
This expects the dispatcher to be a class name.

=item * C<routes>

You can add the routes at the constructor. This is an ArrayRef.

=item * C<known_methods>

Whenever you register a new route this modules checks if the method is either
customer method prefixed with ':' or a $known_method. You would need to change
this, if you would like to implement WebDAV, for example. This is an ArrayRef.

=item * C<auto_respond_404>

If the value for this parameter is set to true a a simple C<404> responder will
be installed that responds if not route matches. You can implement your own
handler see L<EVENTS>.

=back

=item * C<reg_routes( [$method, $path, $callback]* )>

You can add further routes with this method. Multiple routes can be added at
once. To add a route you need do add 3 parameters: <method>, <path>, <callback>.

=item * C<*>

C<AnyEvent::HTTPD::Router> subclasses C<AnyEvent::HTTPD> so you can use all
methods the parent class.

=back

=head1 EVENTS

=over

=item * no_route_found => $request

When the dispatcher can not find a route that matches on your request, the
event C<no_route_found> will be emitted.

In the case that routes and callbacks (C<reg_cb()>) for paths as used with
C<AnyEvent::HTTPD> are mixed, keep in mind that that C<no_route_found> will
happen before the other path callbacks are executed. So for a
C<404 not found> handler you could do

    $httpd->reg_cb('' => sub {
        my ( $httpd, $req ) = @_;
        $req->respond( [ 404, 'not found', {}, '' ] );
    });

If you just use C<reg_routes()> and don't mix with C<reg_cb()> for paths you
could implement the C<404 not found> handler like this:

    $httpd->reg_cb('no_route_found' => sub {
        my ( $httpd, $req ) = @_;
        $req->respond( [ 404, 'not found', {}, '' ] );
    });

This is exactly what you get if you specify C<auto_respond_404> at the
constructor.

=item * See L<AnyEvent::HTTPD/EVENTS>

=back

=head1 WRITING YOUR OWN ROUTE DISPATCHER

If you want to change the implementation of the dispatching you specify the
C<dispatcher> or C<dispatcher_class>. You need to implement the C<match()>
method.

In the case you specify the C<request_class> for C<AnyEvent::HTTPD> you might
need to make adaptions to the C<match()> method as well.

=head1 SEE ALSO

=over

=item * L<AnyEvent>

=item * L<AnyEvent::HTTPD>

=back

There are a lot of HTTP Router modules in CPAN:

=over

=item * L<HTTP::Router>

=item * L<Router::Simple>

=item * L<Router::R3>

=item * L<Router::Boom>

=back

=head1 BUILDING AND RELEASING THIS MODULE

This module uses L<https://metacpan.org/pod/Minilla>.

=head1 LICENSE

Copyright (C) Martin Barth.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 CONTRIBUTORS

=over

=item Paul Koschinski

=back

=head1 AUTHOR

Martin Barth (ufobat)

=cut
