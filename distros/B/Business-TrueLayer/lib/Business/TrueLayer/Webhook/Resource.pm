package Business::TrueLayer::Webhook::Resource;

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
with 'Business::TrueLayer::Role::Status';

no warnings qw/ experimental::signatures experimental::postderef /;

use namespace::autoclean;

has [ qw/ id status / ] => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

=head1 SEE ALSO

L<Business::TrueLayer::Webhook>

=cut

1;
