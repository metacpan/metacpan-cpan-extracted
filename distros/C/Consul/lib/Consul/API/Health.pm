package Consul::API::Health;
$Consul::API::Health::VERSION = '0.021';
use namespace::autoclean;

use Moo::Role;
use Types::Standard qw(Str);

requires qw(_version_prefix _api_exec);

has _health_endpoint => ( is => 'lazy', isa => Str );
sub _build__health_endpoint {
    shift->_version_prefix . '/health';
}

sub health {
    my $self = shift;
    $self = Consul->new(@_) unless ref $self;
    return bless \$self, "Consul::API::Health::Impl";
}

package
    Consul::API::Health::Impl; # hide from PAUSE

use Moo;

use Carp qw(croak);

sub node {
    my ($self, $node, %args) = @_;
    croak 'usage: $health->node($node, [%args])' if grep { !defined } ($node);
    $$self->_api_exec($$self->_health_endpoint."/node/".$node, 'GET', %args, sub {
        [ map { Consul::API::Health::Check->new(%$_) } @{$_[0]} ]
    });
}

sub checks {
    my ($self, $service, %args) = @_;
    croak 'usage: $health->checks($service, [%args])' if grep { !defined } ($service);
    $$self->_api_exec($$self->_health_endpoint."/checks/".$service, 'GET', %args, sub {
        [ map { Consul::API::Health::Check->new(%$_) } @{$_[0]} ]
    });
}

sub service {
    my ($self, $service, %args) = @_;
    croak 'usage: $health->service($service, [%args])' if grep { !defined } ($service);
    $$self->_api_exec($$self->_health_endpoint."/service/".$service, 'GET', %args, sub {
        [ map { Consul::API::Health::Service->new(%$_) } @{$_[0]} ]
    });
}

sub state {
    my ($self, $state, %args) = @_;
    croak 'usage: $health->state($state, [%args])' if grep { !defined } ($state);
    $$self->_api_exec($$self->_health_endpoint."/state/".$state, 'GET', %args, sub {
        [ map { Consul::API::Health::Check->new(%$_) } @{$_[0]} ]
    });
}

package Consul::API::Health::Check;
$Consul::API::Health::Check::VERSION = '0.021';
use Moo;
use Types::Standard qw(Str);

has node         => ( is => 'ro', isa => Str, init_arg => 'Node',        required => 1 );
has id           => ( is => 'ro', isa => Str, init_arg => 'CheckID',     required => 1 );
has name         => ( is => 'ro', isa => Str, init_arg => 'Name',        required => 1 );
has status       => ( is => 'ro', isa => Str, init_arg => 'Status',      required => 1 );
has notes        => ( is => 'ro', isa => Str, init_arg => 'Notes',       required => 1 );
has output       => ( is => 'ro', isa => Str, init_arg => 'Output',      required => 1 );
has service_id   => ( is => 'ro', isa => Str, init_arg => 'ServiceID',   required => 1 );
has service_name => ( is => 'ro', isa => Str, init_arg => 'ServiceName', required => 1 );

package Consul::API::Health::Service;
$Consul::API::Health::Service::VERSION = '0.021';
use Moo;
use Types::Standard qw(ArrayRef);
use Type::Utils qw(class_type);

has node    => ( is => 'ro', isa => class_type('Consul::API::Catalog::ShortNode'),      init_arg => 'Node',    required => 1, coerce => sub { Consul::API::Catalog::ShortNode->new($_[0]) } );
has service => ( is => 'ro', isa => class_type('Consul::API::Agent::Service'),          init_arg => 'Service', required => 1, coerce => sub { Consul::API::Agent::Service->new($_[0]) } );
has checks  => ( is => 'ro', isa => ArrayRef[class_type('Consul::API::Health::Check')], init_arg => 'Checks',  required => 1, coerce => sub { [ map { Consul::API::Health::Check->new($_) } @{$_[0]} ] } );

1;

=pod

=encoding UTF-8

=head1 NAME

Consul::API::Health - Health check API

=head1 SYNOPSIS

    use Consul;
    my $health = Consul->health;

=head1 DESCRIPTION

The Health API is used to query health-related information.

This API is fully documented at L<https://www.consul.io/docs/agent/http/health.html>.

=head1 METHODS

=head2 node

=head2 checks

=head2 service

=head2 state

=head1 SEE ALSO

    L<Consul>

=cut
