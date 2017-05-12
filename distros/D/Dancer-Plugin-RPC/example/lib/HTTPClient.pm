package HTTPClient;
use Moo::Role;

use Scalar::Util 'blessed';
use URI;
use HTTP::Tiny;

our $VERSION = '0.90';

has endpoint => (
    is  => 'ro',
    isa => sub { blessed($_[0]) eq 'URI' }
);
has client => (
    is  => 'lazy',
    isa => sub { blessed($_[0]) eq 'HTTP::Tiny' }
);
has ssl_opts => (
    is      => 'ro',
    default => undef
);
has timeout => (
    is      => 'ro',
    default => 300
);

requires 'call';

around BUILDARGS => sub {
    my $method = shift;
    my $class  = shift;
    my %args = @_;
    if (ref($args{endpoint}) ne 'URI') {
        $args{endpoint} = URI->new($args{endpoint});
    }
    $class->$method(%args);
};

sub _build_client {
    my $self = shift;
    return HTTP::Tiny->new(
        agent      => "XS4ALL-do-rpc/$VERSION",
        verify_SSL => 0,
        timeout    => $self->timeout,
    );
}

1;
