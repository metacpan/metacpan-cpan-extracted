package MyTest::Client;
use Moo;

has ping_value => (is => 'ro', required => 1);

sub call {
    my $self = shift;
    return $self->ping_value;
}

use namespace::autoclean;
1;
