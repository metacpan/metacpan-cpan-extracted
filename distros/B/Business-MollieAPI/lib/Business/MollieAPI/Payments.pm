package Business::MollieAPI::Payments;
use Moo;

has name => (is => 'ro', default => 'payments');

with qw/
Business::MollieAPI::Resource
/;

1;
