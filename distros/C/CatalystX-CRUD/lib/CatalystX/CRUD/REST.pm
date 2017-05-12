package CatalystX::CRUD::REST;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Controller );
use Carp;
use MRO::Compat;
use mro 'c3';
use Data::Dump qw( dump );
use Try::Tiny;

__PACKAGE__->mk_accessors(qw( enable_rpc_compat ));
__PACKAGE__->config( enable_rpc_compat => 0 );

our $VERSION = '0.57';

#warn "REST VERSION = $VERSION";

=head1 NAME

CatalystX::CRUD::REST - RESTful CRUD controller

=head1 SYNOPSIS

    # create a controller
    package MyApp::Controller::Foo;
    use strict;
    use base qw( CatalystX::CRUD::REST );
    use MyForm::Foo;
    
    __PACKAGE__->config(
        form_class              => 'MyForm::Foo',
        init_form               => 'init_with_foo',
        init_object             => 'foo_from_form',
        default_template        => 'path/to/foo/edit.tt',
        model_name              => 'Foo',
        primary_key             => 'id',
        view_on_single_result   => 0,
        page_size               => 50,
        enable_rpc_compat       => 0,
    );
                    
    1;
    
    # now you can manage Foo objects using your MyForm::Foo form class
    # with URIs at:
    #  foo/<pk>
    # and use the HTTP method name to indicate the appropriate action.
    # POST      /foo                -> create new record
    # GET       /foo                -> list all records
    # PUT       /foo/<pk>           -> update record
    # DELETE    /foo/<pk>           -> delete record
    # GET       /foo/<pk>           -> view record
    # GET       /foo/<pk>/edit_form -> edit record form
    # GET       /foo/create_form    -> create record form

    
=head1 DESCRIPTION

CatalystX::CRUD::REST is a subclass of CatalystX::CRUD::Controller.
Instead of calling RPC-style URIs, the REST API uses the HTTP method name
to indicate the action to be taken.

See CatalystX::CRUD::Controller for more details on configuration.

The REST API is designed with identical configuration options as the RPC-style
Controller API, so that you can simply change your @ISA chain and enable
REST features for your application.

B<IMPORTANT:> If you are using a CatalystX::CRUD::REST subclass
in your application, it is important to add the following to your main
MyApp.pm file, just after the setup() call:

 __PACKAGE__->setup();
 
 # add these 3 lines
 use MRO::Compat;
 use mro 'c3';
 Class::C3::initialize();

This is required for Class::C3 to resolve the inheritance chain correctly,
especially in the case where your app is subclassing more than one
CatalystX::CRUD::Controller::* class.

=cut

=head1 METHODS

=head2 edit_form

Acts just like edit() in base Controller class, but with a RESTful name.

=head2 create_form

Acts just like create() in base Controller class, but with a RESTful name.

=cut

sub create_form : Path('create_form') {
    my ( $self, $c ) = @_;
    $self->create($c);
}

sub edit_form : PathPart Chained('fetch') Args(0) {
    my ( $self, $c ) = @_;
    return $self->edit($c);
}

=head2 create

Redirects to create_form().

=cut

# no-op to undo the superclass Local attr
sub create {
    shift->next::method(@_);
}

sub _rest_create : Path('create') {
    my ( $self, $c ) = @_;
    $c->res->redirect(
        $c->uri_for( $self->action_for('create_form'), $c->req->params ) );
}

=head2 rest

Attribute: Path Args

Calls the appropriate method based on the HTTP method name.

=cut

my %http_method_map = (
    'POST'   => 'save',
    'PUT'    => 'save',
    'DELETE' => 'rm',
    'GET'    => 'view'
);

my %rpc_methods
    = map { $_ => 1 } qw( create read update delete edit save rm view );
my %related_methods
    = map { $_ => 1 } qw( add remove list_related view_related view );

sub rest : Path {
    my ( $self, $c, @arg ) = @_;

    my $method = $self->req_method($c);

    if ( !exists $http_method_map{$method} ) {
        $c->res->status(400);
        $c->res->body("Bad HTTP request for method $method");
        return;
    }

    $c->log->debug( "rpc compat mode = " . $self->enable_rpc_compat )
        if $c->debug;
    $c->log->debug( "rest args : " . dump \@arg ) if $c->debug;
    $c->log->debug( "rest action->name=" . $c->action->name ) if $c->debug;

    my $n = scalar @arg;
    if ( $n <= 2 ) {
        $self->_rest( $c, @arg );
    }
    elsif ( $n <= 4 ) {
        $self->_rest_related( $c, @arg );
    }
    else {
        $self->_set_status_404($c);
        return;
    }
}

=head2 default

Attribute: Private

Returns 404 status. In theory, this action is never reached,
and if it is, will log an error. It exists only for debugging
purposes.

=cut

sub default : Private {
    my ( $self, $c, @arg ) = @_;
    $c->log->error("default method reached");
    $self->_set_status_404($c);
}

sub _set_status_404 {
    my ( $self, $c ) = @_;
    $c->res->status(404);
    $c->res->body('Resource not found');
}

sub _rest_related {
    my ( $self, $c, @arg ) = @_;
    my ( $oid, $rel_name, $fval, $rpc ) = @arg;

    $c->log->debug("rest_related OID: $oid") if $c->debug;
    $c->log->debug("rest_related rel_name=$rel_name fval=$fval rpc=$rpc")
        if $c->debug;

    if ($rpc) {
        if ( !$self->enable_rpc_compat or !exists $related_methods{$rpc} ) {
            $c->log->debug("unmapped rpc:$rpc") if $c->debug;
            $self->_set_status_404($c);
            return;
        }
    }

    my $http_method     = $self->req_method($c);
    my $dispatch_method = 'related';
    my $rpc_method;
    if ($rpc) {
        $rpc_method = $rpc;

        # mimic PathPart
        if ( $rpc_method eq 'view' ) {
            $rpc_method = 'view_related';
        }
    }
    elsif ( $http_method eq 'POST' or $http_method eq 'PUT' ) {
        $rpc_method = 'add';
    }
    elsif ( $http_method eq 'DELETE' ) {
        $rpc_method = 'remove';
    }
    elsif ( $http_method eq 'GET' ) {
        if ( $fval eq 'list' ) {
            $rpc_method      = 'list_related';
            $dispatch_method = 'fetch_related';
        }
        elsif ($fval) {
            $rpc_method = 'view_related';
        }
        else {
            $c->res->status(400);
            $c->res->body("Bad HTTP request for method $http_method");
            return;
        }
    }
    else {

        # related() will screen for GET based on config
        # but we do not allow that for REST
        $c->res->status(400);
        $c->res->body("Bad HTTP request for method $http_method");
        return;
    }
    $c->log->debug("rest dispatch: $dispatch_method( $rel_name, $fval )")
        if $c->debug;
    $self->$dispatch_method( $c, $rel_name, $fval );
    $self->_call_rpc_method_as_action( $c, $rpc_method, $oid );
}

sub _rest {
    my ( $self, $c, @arg ) = @_;

    # default oid to emptry string and not 0
    # so we can test for length and
    # still have a false value for fetch()
    my $oid = shift @arg || '';
    my $rpc = shift @arg;

    my $http_method = $self->req_method($c);
    $c->log->debug(
        sprintf(
            "rest OID:%s  rpc:%s  http:%s",
            $oid, ( $rpc || '[undef]' ), $http_method
        )
    ) if $c->debug;

    if ( length $oid and $rpc ) {
        if ( $self->enable_rpc_compat and exists $rpc_methods{$rpc} ) {

            # do nothing - logic below
        }
        elsif ( $self->enable_rpc_compat and $http_method eq 'GET' ) {

            # same logic as !length $oid below:
            # assume that $rpc is a relationship name
            # and a 'list' is being requested
            $c->log->debug(
                "GET request with OID and unknown rpc; assuming 'list_related'"
            ) if $c->debug;
            $self->fetch_related( $c, $rpc );
            $rpc = 'list_related';
        }
        elsif ( !$self->enable_rpc_compat or !exists $rpc_methods{$rpc} ) {
            $self->_set_status_404($c);
            return;
        }
    }

    if ( !length $oid and $http_method eq 'GET' ) {
        $c->log->debug("GET request with no OID") if $c->debug;
        $c->action->name('list');
        $c->action->reverse( join( '/', $c->action->namespace, 'list' ) );
        return $self->list($c);
    }

    # what RPC-style method to call
    my $rpc_method = defined($rpc) ? $rpc : $http_method_map{$http_method};

    # backwards compat naming for RPC style
    if ( $rpc_method =~ m/^(create|edit)$/ ) {
        $rpc_method .= '_form';
    }

    if ( !$self->can($rpc_method) ) {
        $c->log->warn("no such rpc method in class: $rpc_method");
    }

    $self->_call_rpc_method_as_action( $c, $rpc_method, $oid );
}

sub _call_rpc_method_as_action {
    my ( $self, $c, $rpc_method, $oid ) = @_;

    my $break_chain = 0;
    try {
        $self->fetch( $c, $oid );
    }
    catch {
        $c->log->debug( 'caught exception, res->status==' . $c->res->status )
            if $c->debug;
        if ( $c->res->status == 404 ) {
            $c->log->debug('break chain with 404') if $c->debug;
            $break_chain = 1;
        }
    };

    return if $break_chain;

    my $http_method = $self->req_method($c);

    $c->log->debug("rpc: $http_method -> $rpc_method") if $c->debug;

    # so View::TT (others?) auto-template-deduction works just like RPC style
    $c->action->name($rpc_method);
    $c->action->reverse( join( '/', $c->action->namespace, $rpc_method ) );

    return $self->$rpc_method($c);
}

=head2 req_method( I<context> )

Internal method. Returns the HTTP method name, allowing
POST to serve as a tunnel when the C<_http_method> or
C<x-tunneled-method> param is present. 
Since most browsers do not support PUT or DELETE
HTTP methods, you can use the special param to tunnel
the desired HTTP method and then POST instead.

=cut

my @tunnel_param_names = qw( x-tunneled-method _http_method );

sub req_method {
    my ( $self, $c ) = @_;
    if ( uc( $c->req->method ) eq 'POST' ) {
        for my $name (@tunnel_param_names) {
            if ( exists $c->req->params->{$name} ) {
                return uc( $c->req->params->{$name} );
            }
        }
    }
    return uc( $c->req->method );
}

=head2 edit( I<context> )

Overrides base method to disable chaining.

=cut

sub edit { shift->next::method(@_) }

=head2 view( I<context> )

Overrides base method to disable chaining.

=cut

sub view { shift->next::method(@_) }

=head2 save( I<context> )

Overrides base method to disable chaining.

=cut

sub save { shift->next::method(@_) }

=head2 rm( I<context> )

Overrides base method to disable chaining.

=cut

sub rm { shift->next::method(@_) }

=head2 remove( I<context> )

Overrides base method to disable chaining.

=cut

sub remove { shift->next::method(@_) }

=head2 add( I<context> )

Overrides base method to disable chaining.

=cut

sub add { shift->next::method(@_) }

=head2 view_related( I<context> )

Overrides base method to disable chaining.

=cut

sub view_related { shift->next::method(@_) }

=head2 list_related( I<context> )

Overrides base method to disable chaining.

=cut

sub list_related { shift->next::method(@_) }

=head2 delete( I<context> )

Overrides base method to disable chaining.

=cut

sub delete { shift->next::method(@_) }

=head2 read( I<context> )

Overrides base method to disable chaining.

=cut

sub read { shift->next::method(@_) }

=head2 update( I<context> )

Overrides base method to disable chaining.

=cut

sub update { shift->next::method(@_) }

=head2 postcommit( I<context>, I<object> )

Overrides base method to redirect to REST-style URL.

=cut

sub postcommit {
    my ( $self, $c, $o ) = @_;
    my $id = $self->make_primary_key_string($o);

    unless ( defined $c->res->location and length $c->res->location ) {

        if ( $c->action->name eq 'rm' ) {
            $c->response->redirect( $c->uri_for('') );
        }
        else {
            $c->response->redirect( $c->uri_for( '', $id ) );
        }

    }

    $self->next::method( $c, $o );
}

=head2 new

Overrides base method just to call next::method to ensure
config() gets merged correctly.

=cut

sub new {
    my ( $class, $app_class, $args ) = @_;
    return $class->next::method( $app_class, $args );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

