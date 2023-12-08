package Business::TrueLayer::Provider;

=head1 NAME

Business::TrueLayer::Provider - class representing a provider
as used in the TrueLayer v3 API.

=head1 SYNOPSIS

    my $Provider = Business::TrueLayer::Provider->new(
        name => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

use Business::TrueLayer::Provider::Filter;
use Business::TrueLayer::Provider::Scheme;

use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item type (Str)

=item filter

A L<Business::TrueLayer::Provider::Filter> object. Hash refs will be coerced.

=item scheme_selection

A L<Business::TrueLayer::Provider::Scheme> object. Hash refs will be coerced.

=back

=cut

has [ qw/ type / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

coerce 'Business::TrueLayer::Provider::Filter'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Provider::Filter->new( %{ $_ } );
    }
;

has filter => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Provider::Filter',
    coerce   => 1,
    required => 1,
);

coerce 'Business::TrueLayer::Provider::Scheme'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Provider::Scheme->new( %{ $_ } );
    }
;

has scheme_selection => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Provider::Scheme',
    coerce   => 1,
    required => 1,
);

=head1 METHODS

None yet.

=head1 SEE ALSO

L<Business::TrueLayer::Provider::Filter>

L<Business::TrueLayer::Provider::Scheme>

=cut

1;
