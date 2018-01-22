package Consul::API::Status;
$Consul::API::Status::VERSION = '0.023';
use namespace::autoclean;

use Moo::Role;
use Types::Standard qw(Str);

requires qw(_version_prefix _api_exec);

has _status_endpoint => ( is => 'lazy', isa => Str );
sub _build__status_endpoint {
    shift->_version_prefix . '/status';
}

sub status {
    my $self = shift;
    $self = Consul->new(@_) unless ref $self;
    return bless \$self, "Consul::API::Status::Impl";
}

package
    Consul::API::Status::Impl; # hide from PAUSE

use Moo;

use Carp qw(croak);

sub leader {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_status_endpoint."/leader", "GET", %args);
}

sub peers {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_status_endpoint."/peers", "GET", %args);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Consul::API::Status - System status API

=head1 SYNOPSIS

    use Consul;
    my $status = Consul->status;
    my $peers = $status->peers;
    say "@$peers";

=head1 DESCRIPTION

The system status API is used to get information about the status of the Consul
cluster.

This API is fully documented at L<https://www.consul.io/docs/agent/http/status.html>.

=head1 METHODS

=head2 leader

    $status->leader;

Returns the address of the Raft leader for the datacenter in which the agent is
running. Returns an IP:port string.

=head2 peers

    $status->peers;

Retrieves the Raft peers for the datacenter in which the agent is running.
Returns an arrayref of IP:port strings.

=head1 SEE ALSO

    L<Consul>

=cut
