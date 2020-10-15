package Test::Async::Microservice::HelloWorld;

use Moose;
use namespace::autoclean;
use 5.010;
use Scalar::Util qw(blessed);
use Plack::Test::Server;
use Plack::Builder;
use Carp qw(croak);

use Async::Microservice::Time;

has '_service' => (
    is        => 'ro',
    lazy      => 1,
    builder   => '_build__service',
    predicate => 'is_running'
);

sub _build__service {
    my ($self) = @_;

    my $mise = Async::Microservice::HelloWorld->new();
    my $app = sub { $mise->plack_handler(@_) };

    my $time_service = builder {
        enable "Plack::Middleware::ContentLength";
        $app;
    };
    my $t_server = Plack::Test::Server->new($time_service);
    $self->{_url} = 'http://127.0.0.1:'.$t_server->port.'/v1/';
    return $t_server;
}

sub start {
    my ($self) = @_;
    $self = $self->new
        unless blessed($self);

    $self->_service;

    return $self;
}

sub url {
    my ($self) = @_;
    croak 'not running'
        unless $self->is_running;
    return $self->{_url};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Test::Async::Microservice::Time - init and configure Async-Microservice-Time for testing

=head1 DESCRIPTION

See F<t/02_Async-Microservice-Time.t>.

=cut
