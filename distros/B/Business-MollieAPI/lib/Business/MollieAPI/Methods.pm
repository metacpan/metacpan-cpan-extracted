package Business::MollieAPI::Methods;
use Moo;

has name => (is => 'ro', default => 'methods');

with qw/
Business::MollieAPI::Resource
/;

1;

