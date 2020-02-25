package Consul::API::Agent;
$Consul::API::Agent::VERSION = '0.027';
use namespace::autoclean;

use Moo::Role;
use Types::Standard qw(Str);

requires qw(_version_prefix _api_exec);

has _agent_endpoint => ( is => 'lazy', isa => Str );
sub _build__agent_endpoint {
    shift->_version_prefix . '/agent';
}

sub agent {
    my $self = shift;
    $self = Consul->new(@_) unless ref $self;
    return bless \$self, "Consul::API::Agent::Impl";
}

package
    Consul::API::Agent::Impl; # hide from PAUSE

use Moo;

use Consul::Check;
use Consul::Service;

use Carp qw(croak);
use Scalar::Util qw( blessed );

sub checks {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_agent_endpoint."/checks", 'GET', %args, sub {
        [ map { Consul::API::Agent::Check->new(%$_) } values %{$_[0]} ]
    });
}

sub services {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_agent_endpoint."/services", 'GET', %args, sub {
        [ map { Consul::API::Agent::Service->new(%$_) } values %{$_[0]} ]
    });
}

sub members {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_agent_endpoint."/members", 'GET', %args, sub {
        [ map { Consul::API::Agent::Member->new(%$_) } @{$_[0]} ]
    });
}

sub self {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_agent_endpoint."/self", 'GET', %args, sub {
        Consul::API::Agent::Self->new(%{$_[0]})
    });
}

sub maintenance {
    my ($self, $enable, %args) = @_;
    croak 'usage: $agent->maintenance($enable, [%args])' if grep { !defined } ($enable);
    $$self->_api_exec($$self->_agent_endpoint."/maintenance", 'PUT', enable => ($enable ? "true" : "false"), %args);
    return;
}

sub join {
    my ($self, $address, %args) = @_;
    croak 'usage: $agent->join($address, [%args])' if grep { !defined } ($address);
    $$self->_api_exec($$self->_agent_endpoint."/join/".$address, 'PUT', %args);
    return;
}

sub force_leave {
    my ($self, $node, %args) = @_;
    croak 'usage: $agent->force_leave($node, [%args])' if grep { !defined } ($node);
    $$self->_api_exec($$self->_agent_endpoint."/force-leave/".$node, 'PUT', %args);
    return;
}

sub check_register {
    my ($self, $check, %args) = @_;
    croak 'usage: $agent->check_register($check, [%args])' if grep { !defined } ($check);
    {
        local $Carp::CarpInternal{ (__PACKAGE__) } = 1;
        $check = Consul::Check->smart_new($check) if !blessed $check;
    }
    $$self->_api_exec($$self->_agent_endpoint."/check/register", 'PUT', %args, _content => $check->to_json);
    return;
}

sub check_deregister {
    my ($self, $check_id, %args) = @_;
    croak 'usage: $agent->check_deregister($check_id, [%args])' if grep { !defined } ($check_id);
    $$self->_api_exec($$self->_agent_endpoint."/check/deregister/".$check_id, 'PUT', %args);
    return;
}

sub check_pass {
    my ($self, $check_id, %args) = @_;
    croak 'usage: $agent->check_pass($check_id, [%args])' if grep { !defined } ($check_id);
    $$self->_api_exec($$self->_agent_endpoint."/check/pass/".$check_id, 'PUT', %args);
    return;
}

sub check_warn {
    my ($self, $check_id, %args) = @_;
    croak 'usage: $agent->check_warn($check_id, [%args])' if grep { !defined } ($check_id);
    $$self->_api_exec($$self->_agent_endpoint."/check/warn/".$check_id, 'PUT', %args);
    return;
}

sub check_fail {
    my ($self, $check_id, %args) = @_;
    croak 'usage: $agent->check_fail($check_id, [%args])' if grep { !defined } ($check_id);
    $$self->_api_exec($$self->_agent_endpoint."/check/fail/".$check_id, 'PUT', %args);
    return;
}

sub service_register {
    my ($self, $service, %args) = @_;
    croak 'usage: $agent->service_register($service, [%args])' if grep { !defined } ($service);
    $service = Consul::Service->new($service) if !blessed $service;
    $$self->_api_exec($$self->_agent_endpoint."/service/register", 'PUT', %args, _content => $service->to_json);
    return;
}

sub service_deregister {
    my ($self, $service_id, %args) = @_;
    croak 'usage: $agent->service_deregister($check_id, [%args])' if grep { !defined } ($service_id);
    $$self->_api_exec($$self->_agent_endpoint."/service/deregister/".$service_id, 'PUT', %args);
    return;
}

sub service_maintenance {
    my ($self, $service_id, $enable, %args) = @_;
    croak 'usage: $agent->service_maintenance($service_id, $enable, [%args])' if grep { !defined } ($service_id, $enable);
    $$self->_api_exec($$self->_agent_endpoint."/service/maintenance/".$service_id, 'PUT', enable => ($enable ? "true" : "false"), %args);
    return;
}

package Consul::API::Agent::Check;
$Consul::API::Agent::Check::VERSION = '0.027';
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

package Consul::API::Agent::Service;
$Consul::API::Agent::Service::VERSION = '0.027';
use Moo;
use Types::Standard qw(Str Int ArrayRef);

has id      => ( is => 'ro', isa => Str,           init_arg => 'ID',      required => 1 );
has service => ( is => 'ro', isa => Str,           init_arg => 'Service', required => 1 );
has address => ( is => 'ro', isa => Str,           init_arg => 'Address', required => 1 );
has port    => ( is => 'ro', isa => Int,           init_arg => 'Port',    required => 1 );
has tags    => ( is => 'ro', isa => ArrayRef[Str], init_arg => 'Tags',    required => 1, coerce => sub { $_[0] || [] } );

package Consul::API::Agent::Member;
$Consul::API::Agent::Member::VERSION = '0.027';
use Moo;
use Types::Standard qw(Str Int HashRef);

has name         => ( is => 'ro', isa => Str,          init_arg => 'Name',        required => 1 );
has addr         => ( is => 'ro', isa => Str,          init_arg => 'Addr',        required => 1 );
has port         => ( is => 'ro', isa => Int,          init_arg => 'Port',        required => 1 );
has tags         => ( is => 'ro', isa => HashRef[Str], init_arg => 'Tags',        required => 1, coerce => sub { $_[0] || {} } );
has status       => ( is => 'ro', isa => Int,          init_arg => 'Status',      required => 1 );
has protocol_min => ( is => 'ro', isa => Int,          init_arg => 'ProtocolMin', required => 1 );
has protocol_max => ( is => 'ro', isa => Int,          init_arg => 'ProtocolMax', required => 1 );
has protocol_cur => ( is => 'ro', isa => Int,          init_arg => 'ProtocolCur', required => 1 );
has delegate_min => ( is => 'ro', isa => Int,          init_arg => 'DelegateMin', required => 1 );
has delegate_max => ( is => 'ro', isa => Int,          init_arg => 'DelegateMax', required => 1 );
has delegate_cur => ( is => 'ro', isa => Int,          init_arg => 'DelegateCur', required => 1 );

package Consul::API::Agent::Self;
$Consul::API::Agent::Self::VERSION = '0.027';
use Moo;
use Types::Standard qw(HashRef);
use Type::Utils qw(class_type);

# XXX raw hash. not happy about this, but the list of config keys don't seem to be consistent across environments
has config => ( is => 'ro', isa => HashRef,                                  init_arg => 'Config', required => 1, coerce => sub { $_[0] || {} } );
has member => ( is => 'ro', isa => class_type('Consul::API::Agent::Member'), init_arg => 'Member', required => 1, coerce => sub { Consul::API::Agent::Member->new($_[0]) } );

1;

=pod

=encoding UTF-8

=head1 NAME

Consul::API::Agent - Agent API

=head1 SYNOPSIS

    use Consul;
    my $agent = Consul->agent;
    $agent->self;

=head1 DESCRIPTION

The Agent API is used to interact with the local Consul agent.

This API is fully documented at L<https://www.consul.io/docs/agent/http/agent.html>.

=head1 METHODS

=head2 checks

=head2 services

=head2 members

=head2 self

=head2 maintenance

=head2 join

=head2 force_leave

=head2 check_register

=head2 check_deregister

=head2 check_pass

=head2 check_warn

=head2 check_fail

=head2 service_register

=head2 service_deregister

=head2 service_maintenance

=head1 SEE ALSO

    L<Consul>

=cut
