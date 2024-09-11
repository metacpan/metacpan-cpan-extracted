package Business::TrueLayer::Types::Remitter;

use strict;
use warnings;

use Moose::Role;
use Moose::Util::TypeConstraints;

use Business::TrueLayer::Remitter;

use namespace::autoclean;

coerce 'Business::TrueLayer::Remitter'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Remitter->new( %{ $_ } );
    }
;

has remitter => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Remitter',
    coerce   => 1,
    required => 0,
);

1;

# vim: ts=4:sw=4:et
