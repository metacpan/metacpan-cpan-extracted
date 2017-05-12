package Box2D;

use warnings;
use strict;
our @ISA = qw(Exporter);

our $VERSION = '0.07';

require XSLoader;
XSLoader::load( 'Box2D', $VERSION );
require Exporter;

our @EXPORT_OK   = ();
our %EXPORT_TAGS = ();

use constant {

    #b2Body Type
    b2_staticBody    => 0,
    b2_kinematicBody => 1,
    b2_dynamicBody   => 2,

    #b2Shape Type
    e_unknown   => -1,
    e_circle    => 0,
    e_polygon   => 1,
    e_typeCount => 2,

};

BEGIN {
    *Box2D::b2World::SetContactListener = sub {
        if ( UNIVERSAL::isa( $_[1], "Box2D::b2ContactListener" ) ) {
            $_[0]->SetContactListenerXS( $_[1]->_getListener() );
        }
        else {
            $_[0]->SetContactListenerXS( $_[1] );
        }
    };

    *Box2D::b2World::RayCast = sub {
        my $world    = shift;
        my $callback = shift;
        if ( UNIVERSAL::isa( $callback, "Box2D::b2RayCastCallback" ) ) {
            $world->RayCastXS( $callback->_getCallback(), @_ );
        }
        else {
            $world->RayCastXS( $callback, @_ );
        }
    };
}

package    # Hide from PAUSE
    Box2D::b2Vec2;

use overload
    '+'    => '_add',
    '-'    => '_sub',
    '*'    => '_mul',
    '=='   => '_eql',
    'bool' => sub {1};

sub _add {
    my ( $self, $other ) = @_;

    return Box2D::b2Math::b2AddV2V2( $other, $self );
}

sub _sub {
    my ( $self, $other, $swap ) = @_;

    if ($swap) {
        return Box2D::b2Math::b2SubV2V2( $other, $self );
    }
    else {
        return Box2D::b2Math::b2SubV2V2( $self, $other );
    }
}

# Multiplication is defined between a vector and scalar. Multiplying two
# vectors is ambiguous because either cross product or dot product may
# be intended. Use b2CrossV2V2 or b2DotV2V2 for those operations.
sub _mul {
    my ( $self, $other ) = @_;

    return Box2D::b2Math::b2MulSV2( $other, $self );
}

sub _eql {
    my ( $self, $other ) = @_;

    return Box2D::b2Math::b2EqlV2V2( $self, $other );
}

1;    # End of Box2D
