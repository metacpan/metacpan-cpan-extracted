package Apache2::REST::ErrorOutputRegistry;
use Apache2::REST::ErrorOutputHandler::both ;
use Apache2::REST::ErrorOutputHandler::response ;
use Apache2::REST::ErrorOutputHandler::server ;
use strict ;

=head1 NAME

Apache2::REST::ErrorOutputRegistry - Manages instances of ErrorOutputHandler

=cut

use base qw/Class::AutoAccess/ ;

my $singleton = undef ;

=head2 instance

Returns the singleton instance of the registry.

=cut

sub instance{
    my ($class) = @_ ;
    unless ($singleton){
        $singleton = {
            'register' => {},
        };
        bless $singleton , $class ;
        $singleton->buildRegister() ;
    }
    return $singleton ;
}


sub buildRegister{
    my ( $self ) = @_ ;
    
    $self->registerEO('both' , Apache2::REST::ErrorOutputHandler::both->new()) ;
    $self->registerEO('response' , Apache2::REST::ErrorOutputHandler::response->new()) ;
    $self->registerEO('server'  , Apache2::REST::ErrorOutputHandler::server->new()) ;
}


=head2 registerEO

Registers an instance of ErrorOutputHandler

=cut

sub registerEO{
    my ( $self , $key , $eoInstance ) = @_ ;
    unless( $eoInstance->isa('Apache2::REST::ErrorOutputHandler')){
        
    }
    $self->register()->{$key} = $eoInstance ;
}


=head2 getOutput

Returns the ErrorOutputHandler registered with key

Usage:

    Apache2::REST::ErrorOutputRegister->instance()->getOutput('both') ; # For instance.

=cut

sub getOutput{
    my ( $self , $key ) = @_ ;
    
    if ( $self->register()->{$key} ){
        return $self->register()->{$key} ;
    }
    warn "NO ErrorOutput instance found for $key. Using 'both'\n";
    return $self->register->{'both'};
}


1;
