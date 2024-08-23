package Business::TrueLayer::Types::User;

use strict;
use warnings;

use Moose::Role;
use Moose::Util::TypeConstraints;

use Business::TrueLayer::User;

use namespace::autoclean;

coerce 'Business::TrueLayer::User'
    => from 'HashRef'
    => via {
        Business::TrueLayer::User->new( %{ $_ } );
    }
;

has user => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::User',
    coerce   => 1,
    required => 1,
);

1;

# vim: ts=4:sw=4:et
