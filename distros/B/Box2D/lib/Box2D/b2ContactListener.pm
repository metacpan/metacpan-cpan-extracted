package Box2D::b2ContactListener;
use strict;
use Box2D;

BEGIN {
 
#    { #make a new scope for the wrapper;
#        *Box2D::b2World::SetContactListenerXS = *Box2D::b2World::SetContactListener;
#        *Box2D::b2World::SetContactListener = sub {
#            my ($self, $listener) = @_;
#            if (UNIVERSAL::isa($listener,"Box2D::b2ContactListener")) {
#                Box2D::b2World::SetContactListenerXS( $self, $listener->_getListener() );
#            } else {
#                Box2D::b2World::SetContactListenerXS( $self, $listener );
#            }
#        };
#    }
}
#use base qw(Box2D::PerlContactListener);

# this class is a wrapper for the PerlContactListener 
# to allow you to make b2ContactListeners via inheritance

sub new {
    my($class) = @_; 
    my $self = { };
    bless($self, $class);          # Say: $self is a $class
    $self->{_listener} = Box2D::PerlContactListener->new();
    $self->setOurListeners();
    return $self;
}

# overload these
sub BeginContact {}

sub EndContact {}

sub PreSolve {}

sub PostSolve {}

# this will make sure that the right subs are set
sub setOurListeners {
    my ($self) = @_;
    $self->{_listener}->SetBeginContactSub( sub { $self->BeginContact(@_); } );
    $self->{_listener}->SetEndContactSub( sub { $self->EndContact(@_); } );
    $self->{_listener}->SetPostSolveSub( sub { $self->PostSolve(@_); } );
    $self->{_listener}->SetPreSolveSub( sub { $self->PreSolve(@_); } );
}

sub _getListener {
    my ($self) = @_;
    return $self->{_listener};
}

1;
