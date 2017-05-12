#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Controller::ExtJS::Direct::API;
$CatalystX::Controller::ExtJS::Direct::API::VERSION = '2.1.5';
# ABSTRACT: API and router controller for Ext.Direct
use Moose;
extends qw(Catalyst::Controller::REST);
use MooseX::MethodAttributes;

use List::Util qw(first);
use List::MoreUtils ();
use Scalar::Util qw(blessed);
use JSON ();
use CatalystX::Controller::ExtJS::Direct::Route;

__PACKAGE__->config(
    
    action => {
        end    => { ActionClass => '+CatalystX::Action::ExtJS::Serialize' },
        begin  => { ActionClass => '+CatalystX::Action::ExtJS::Deserialize' },
        index  => { Path        => undef },
        router => { Path        => 'router' },
        src    => { Local => undef },
    },
    
    default => 'application/json'
    
);


has 'api' => ( is => 'rw', lazy_build => 1 );

has 'routes' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has 'namespace' => ( is => 'rw' );

sub index { }

sub src {
    my ($self, $c) = @_;
    $c->res->content_type('application/javascript');
    $c->res->body( 'Ext.app.REMOTING_API = ' . $self->encoded_api($c) . ';' );
}

sub _build_api {
    my ($self) = @_;
    my $c      = $self->_app;
    my $data   = {};
    foreach my $name ( $c->controllers ) {
        my $controller = $c->controller($name);
        $name =~ s/^API:://;
        $name =~ s/:://g;
        my $meta       = $controller->meta;
        next
          unless ( $controller->can('is_direct') || $meta->does_role('CatalystX::Controller::ExtJS::Direct') );
        my @methods;
        foreach my $method ( sort { $a->name cmp $b->name } $controller->get_action_methods ) {
            next
              unless ( my $action = $controller->action_for( $method->name ) );
            next unless ( exists $action->attributes->{Direct} );
            my @routes =
              CatalystX::Controller::ExtJS::Direct::Route::Factory->build(
                $c->dispatcher, $action );
            foreach my $route (@routes) {
                $self->routes->{$name}->{ $route->name } = $route;
                push( @methods, $route->build_api );
            }

        }
        $data->{$name} = [@methods];
    }
    return {
        url => $c->dispatcher->uri_for_action( $self->action_for('router') )
          ->as_string,
        type    => 'remoting',
        actions => $data
    };
}

sub encoded_api {
    my ( $self, $c ) = @_;
    return JSON::encode_json( $self->set_namespace( $self->api, $c ? $c->req->params->{namespace} : () ) );
}

sub router {
    my ( $self, $c ) = @_;
    my $reqs = ref $c->req->data eq 'ARRAY' ? $c->req->data : [ $c->req->data ];
    my $api    = $self->api;      # populates $self->routes
    my $routes = $self->routes;
    if ( keys %{ $c->req->body_params }
        && ( my $params = $c->req->body_params ) )
    {
        $reqs = [
            {
                map {
                    my $orig = $_;
                    $orig =~ s/^ext//;
                    ( lc($orig) => delete $params->{$_} )
                  } qw(extType extAction extMethod extTID extUpload)
            }
        ];
        if ( $params->{extData} ) {
            $reqs->[0]->{data} = JSON::decode_json( delete $params->{extData} );
        } else {
            $reqs->[0]->{data} = [{%$params}];
        }
    }
    
    my @requests;
    
    foreach my $req (@$reqs) {
        unless ( $req && $req->{action}
            && exists $routes->{ $req->{action} }
            && exists $routes->{ $req->{action} }->{ $req->{method} } )
        {
            $self->status_bad_request( $c, { message => sprintf('method %s in action %s does not exist', $req->{method} || '', $req->{action} || '') } );
            return;
        }
         my $route = $routes->{ $req->{action} }->{ $req->{method} };
        
        push(@requests, $route->prepare_request($req));

    }
    
    my @res;
    REQUESTS:
    foreach my $req (@requests) {
        $req->{data} = [$req->{data}] if(ref $req->{data} ne "ARRAY");
        $c->stash->{upload} = 1 if ( $req->{upload} );
        
        my $route = $routes->{ $req->{action} }->{ $req->{method} };
        my $params = @{$req->{data}} && ref $req->{data}->[-1] eq 'HASH' ? $req->{data}->[-1] : undef;
        my $body;
        {
            local $c->{response} = $c->response_class->new({});
            local $c->{stash} = {};
            local $c->{request} = $c->req;
            local $c->{error} = undef;
            
            $c->req->parameters($params);
            $c->req->body_parameters($params);
            my %req = $route->request($req);
            $c->req($c->request_class->new(%{$c->req}, %req));
            eval {
                $c->visit($route->build_url( $req->{data} ));
                my $response = $c->res;
                if ( $response->content_type eq 'application/json' ) {
                    (my $res_body = $response->body || '') =~ s/^\xEF\xBB\xBF//; # remove BOM
                    my $json = JSON::decode_json( $res_body );
                    $body = $json;
                } else {
                    $body = $response->body;
                }
                
                if(@{$c->error}) { 0 }
                elsif($response->status >= 400) {
                    $c->error($body);
                    0;
                } else { 1 } 
            } or do {
                my $msg;
                if(@{ $c->error } && List::MoreUtils::all { ref $_ } @{ $c->error }) {
                    $msg = @{$c->error} == 1 ? $c->error->[0] : $c->error;
                    $msg = "$msg" if(blessed $msg);
                } elsif(scalar @{ $c->error }) {
                    $msg = join "\n", map { blessed $_ ? "$_" : $_ } @{ $c->error };
                } else {
                    $msg = join("\n", "$@", $c->response->body || ());
                }
                push(@res, { type => 'exception', tid => $req->{tid}, message => $msg, status_code => $c->res->status });
                $c->log->error($msg) if($c->debug && !ref $msg);
                next REQUESTS;
            };
            
            
            
        }

        my $res = { map { $_ => $req->{$_} } qw(action method tid type) };
        push( @res, { %$res, result => $body } );

    }
    $c->stash->{rest} = @res != 1 ? \@res : $res[0];

}

sub set_namespace {
    my ($self, $api, $namespace) = @_;
    return $api unless($namespace && $namespace =~ /^\w+(\.\w+)?$/);
    return {%$api, namespace => $namespace };
}

sub end {
    my ( $self, $c ) = @_;
    $c->stash->{rest} ||= $self->set_namespace( $self->api, $c->req->params->{namespace} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Controller::ExtJS::Direct::API - API and router controller for Ext.Direct

=head1 VERSION

version 2.1.5

=head1 SYNOPSIS

 package MyApp::Controller::API;
 use Moose;
 extends 'CatalystX::Controller::ExtJS::Direct::API';
 1;

 <script type="text/javascript" src="/api/src?namespace=MyApp.Direct"></script>
 <script>Ext.Direct.addProvider(Ext.app.REMOTING_API);</script>

=head1 ACTIONS

=head2 router

Every request to the API is going to hit this action, since the API's url will point to this action. 

You can change the url to this action via the class configuration.

Example:

  package MyApp::Controller::API;
  __PACKAGE__->config( action => { router => { Path => 'callme' } } );
  1;

The router is now available at C<< /api/callme >>.

=head2 src

Provides the API as JavaScript. Include this action in your web application as shown in the L</SYNOPSIS>.
To set the namespace for the API, pass a C<namespace> query parameter:

  <script type="text/javascript" src="/api/src?namespace=MyApp.Direct"></script>

=head2 index

This action is called when you access the namespace of the API. It will load L</api> and return
the JSON encoded API to the client. Since this class utilizes L<Catalyst::Controller::REST> you
can specify a content type in the request header and get the API encoded accordingly.

=head1 METHODS

=head2 api

Returns the API as a HashRef.

Example:

 {
    url => '/api/router',
    type => 'remote',
    actions => {
        Calc => {
            methods => [
                    { name => 'add', len => 2 },
                    { name => 'subtract', len => 0 }
                ]
        }
    }
  }

=head2 encoded_api

This method returns the JSON encoded API which is useful when you want to include the API in a JavaScript file.

Example:

  Ext.app.REMOTING_API = [% c.controller('API').encoded_api %];
  Ext.Direct.addProvider(Ext.app.REMOTING_API);
  
  Calc.add(1, 3, function(provider, response) {
    // process response
  });

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
