package MyApp::FakeCHI;

use Moo;
use strictures 2;
use namespace::clean;

has _cache => (
    is       => 'ro',
    init_arg => undef,
    default  => sub{ {} },
);

sub set {
    my ($self, $key, $value) = @_;
    $self->_cache->{$key} = $value;
    return;
}

sub get {
    my ($self, $key) = @_;
    return $self->_cache->{$key};
}

1;
