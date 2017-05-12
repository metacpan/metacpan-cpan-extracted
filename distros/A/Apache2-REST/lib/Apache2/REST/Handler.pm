package Apache2::REST::Handler ;

use strict ;
use warnings ;

use Data::Dumper ;
use Apache2::Const qw( 
                       :common :http 
                       );

use Apache2::REST::Conf ;
use Apache2::REST::ErrorOutputRegistry ;

use base qw/Class::AutoAccess/ ;

=head1 NAME

Apache2::REST::Handler - Base class for a resource handler.

=head1 SYNOPSIS

A Handler object is build for each fragment of the URI, and objects are chained via the attibute parent.

You _must_ implement at list one Handler class to handle the root URI of your application and set it in your
apache conf by : PerlSetVar Apache2RESTHandlerRootClass "MyApp::REST::API" (for instance).

You _must_ implement at least one HTTP method (GET,POST,PUT,DELETE ...).

They will be called by the framework like this (for instance):

 $this->GET($request,$response) ;

$request is an Apache2::REST::Request (which is a subclass of Apache2::Request).
$response is an Apache2::REST::Response 


Each method must return a valid Apache2::Const::HTTP_* code. 
Typically Apache2::Const::HTTP_OK when everything went smoothly.

See http://search.cpan.org/dist/Apache2-Controller/lib/Apache2/Controller/Refcard.pm for a list.

You _must_ implement at least one isAuth method along the URI. Typically if you want to allow GET by default:

    sub isAuth{ my ( $self , $method , $req  ) = @ _; return $method eq 'GET' ;}


See L<Apache2::REST> for a full working handler example.


=head2 class

Helper to get the class of this (or this class).

=cut

sub class{
    my ( $self ) = @ _;
    return ref $self || $self ;
}

=head2 handle

Handles a request and does the framework magic.
Override at your own risks.

=cut

sub handle{
    my ( $self , $stack , $req , $resp ) = @_ ;
    #warn "Handling ".Dumper($stack)."\n" ;
    if ( 0 == @$stack ){
        my $method = $req->method();
        ## Check auth first
        if ( $self->isAuth($method , $req )){
            unless( $self->can($method)){
                $resp->message('Method '.$method.' not implemented');
                $resp->status(HTTP_NOT_IMPLEMENTED);
                return HTTP_NOT_IMPLEMENTED ;
            }
            my $res = undef;
            eval{
                $res = $self->$method($req,$resp) ;
            };
            if ( $@ ){
                my $err = $@ ;
                Apache2::REST::ErrorOutputRegistry->instance()->getOutput($self->conf()->Apache2RESTErrorOutput())->handle($err,$resp, $req);
                
                $resp->status(HTTP_INTERNAL_SERVER_ERROR);
                return HTTP_INTERNAL_SERVER_ERROR ;
            }
            $resp->status($res) ;
            return $res ;
        }else{
            $resp->status(HTTP_UNAUTHORIZED) ;
            $resp->message('method unauthorized') ;
            return HTTP_UNAUTHORIZED ;
        }
    }
    my $fragment = shift @$stack ;
    my $subh = $self->buildNext($fragment , $req ) ;
    unless( $subh ){
        $resp->status(HTTP_NOT_FOUND);
        $resp->message('Resource not found for '.$fragment) ;
        return HTTP_NOT_FOUND ;
    }
    return $subh->handle($stack , $req , $resp ) ;
}

=head2 buildNext

This method is responsible for building the handler handling the next fragment.
It is given the fragment to build an handler for as well as the Request.

The default implementation builds a handler of class $this->class().'::'.$frag 

It _must_ return undef when the resource is not found.

Called like this by the framework:

$this->buildNext($frag , $req ) ;

Overriding use cases:

- Build a dynamic handler.
  For instance if the fragment is an item ID, you might want to build an item handler with this particular item. See L<Apache2::REST::Handler::test> for an example.

- Rerouting outside of the handler classes space.
  If you want to escape the default class resolution mecanism.


=cut

sub buildNext{
    my ( $self , $frag , $req ) = @_ ;
    ## default implementation
    
    my $newC = $self->class().'::'.$frag ;
    eval "require $newC;";
    if ( $@ ){
        warn "Class $newC not found: $@\n" ;
        return undef ;
    }
    return $newC->new($self) ;
}


=head2 isAuth

Given a method and a request, returns true if this method is allowed.

The default implementation delegates to the parent.

Nothing is allowed by default. So you need to override this method at least once.

It is called by the framework like this (for instance):

$this->isAuth('GET' , $req) ;

=cut

sub isAuth{
    my ( $self , $method , $req  ) = @ _;
    if ( $self->parent()){
        return $self->parent()->isAuth($method , $req ) || 0 ;
    }
    return 0 ;
}

=head2 new

You can override this in subclasses. Do not forget to call $class->SUPER::new() ;

=cut

sub new{
    my ( $class , $parent ) = @_ ;
    my $self = {
        'parent' => $parent ,
    };
    # Enforce the presence of the _conf attribute.
    if ( $parent ){
        $self->{'_conf'} = $parent->conf() ;
    }else{
        $self->{'_conf'} = Apache2::REST::Conf->new()  ;
    }
    return bless $self , $class ;
}

=head2 conf

Get/Sets the configuration attached to this handler.
Or the parent one if no one is defined.

=cut

sub conf{
    my ( $self , $newC ) = @_ ;
    if ( defined $newC ){
        $self->{'_conf'} = $newC ;
    }
    return $self->{'_conf'} || $self->parent()->conf() ;
}

=head2 isTopLevel

Returns true if this handler handles the application top level.

Usage:
    
    if ( $this->isTopLevel() ){ .. }

=cut

sub isTopLevel{
    my ( $self ) = @_ ;
    return ! $self->parent() ;
}


=head2 rootHandler

Returns the root handler processing this request.

=cut

sub rootHandler{
    my ( $self ) = @_ ;
    if ( $self->isTopLevel() ){ return $self ;}
    return $self->parent()->rootHandler() ;
}


=head2 seekByClass
    
Seek for a handler of the given class along the parent path.
Returns the first handler found or undef if nothing found.
    
usage:
    
    my $handler = $self->seekByClass('My::REST::API::myclass') ;

=cut

sub seekByClass{
    my ($self ,$className) = @_ ;
    if ( $self->class() eq $className ){
        return $self ;
    }
    if ( $self->isTopLevel()){ return undef ;}
    return $self->parent()->seekByClass($className) ;
}


1 ;

#GET
#POST
#PUT
#DELETE
#new
