package Business::TrueLayer::Types::Beneficiary;

use strict;
use warnings;

use Moose::Role;
use Moose::Util::TypeConstraints;

use Business::TrueLayer::Beneficiary;

use namespace::autoclean;

coerce 'Business::TrueLayer::Beneficiary'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Beneficiary->new( %{ $_ } );
    }
;

has beneficiary => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Beneficiary',
    coerce   => 1,
    required => 1,
);

1;

# vim: ts=4:sw=4:et
