package Business::TrueLayer::Remitter;

=head1 NAME

Business::TrueLayer::Remitter - class representing a remitter
as used in the TrueLayer v3 API.

=head1 SYNOPSIS

    my $Remitter = Business::TrueLayer::Remitter->new(
        type => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
extends 'Business::TrueLayer::Request';
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

use namespace::autoclean;

use Business::TrueLayer::Address;
use Business::TrueLayer::Account::Identifier;

=head1 ATTRIBUTES

=over

=item account_holder_name (Str)

=cut

has [ qw/ account_holder_name / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

coerce 'Business::TrueLayer::Address'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Address->new( %{ $_ } );
    }
;

has address => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Address',
    coerce   => 1,
    required => 0,
);

coerce 'Business::TrueLayer::Account::Identifier'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Account::Identifier->new( %{ $_ } );
    }
;

has account_identifier => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Account::Identifier',
    coerce   => 1,
    required => 1,
);

=head1 SEE ALSO

L<Business::TrueLayer::Beneficiary>

=cut

1;
