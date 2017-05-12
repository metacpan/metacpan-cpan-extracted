package Business::MollieAPI::Issuers;
use Moo;

has name => (is => 'ro', default => 'issuers');

with qw/
Business::MollieAPI::Resource
/;

1;
