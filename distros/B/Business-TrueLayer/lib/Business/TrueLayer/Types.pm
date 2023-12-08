package Business::TrueLayer::Types;

use strict;
use warnings;

use Moose::Util::TypeConstraints;

# objects can be Test::MockObject(s) so we can do "end to end"
# testing without actually going out on the wire
subtype 'UserAgent'
    => as 'Object'
    => where {
        $_->isa( 'Mojo::UserAgent' )
        or $_->isa( 'Test::MockObject' )
    }
;

subtype 'Authenticator'
    => as 'Object'
    => where {
        $_->isa( 'Business::TrueLayer::Authenticator' )
        or $_->isa( 'Test::MockObject' )
    }
;

subtype 'Signer'
    => as 'Object'
    => where {
        $_->isa( 'Business::TrueLayer::Signer' )
        or $_->isa( 'Test::MockObject' )
    }
;

subtype 'EC512:PrivateKey'
    => as 'Object'
    => where {
        $_->isa( 'Crypt::PK::ECC' )
    }
;

coerce 'EC512:PrivateKey'
    => from 'Value'
    => via {
        Crypt::PK::ECC->new( $_ )
    }
;

1;

# vim: ts=4:sw=4:et
