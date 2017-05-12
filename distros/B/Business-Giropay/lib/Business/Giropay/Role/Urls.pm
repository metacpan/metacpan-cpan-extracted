package Business::Giropay::Role::Urls;

=head1 NAME

Business::Giropay::Role::Urls - 'urls' role for urlRedirect and urlNotify

=cut

use Business::Giropay::Types qw/Str/;
use Moo::Role;

=head1 ATTRIBUTES

=head2 urlRedirect

Shop URL to which the customer is to be sent after the payment.

=cut

has urlRedirect => (
    is       => 'ro',
    isa      => Str,
);

=head2 urlNotify

Shop URL to which the outgoing payment is reported.

=cut

has urlNotify => (
    is       => 'ro',
    isa      => Str,
);

1;
