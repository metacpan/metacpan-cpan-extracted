package Consul::API::Catalog;
$Consul::API::Catalog::VERSION = '0.020';
use namespace::autoclean;

use Moo::Role;
use Types::Standard qw(Str);

requires qw(_version_prefix _api_exec);

has _catalog_endpoint => ( is => 'lazy', isa => Str );
sub _build__catalog_endpoint {
    shift->_version_prefix . '/catalog';
}

sub catalog {
    my $self = shift;
    $self = Consul->new(@_) unless ref $self;
    return bless \$self, "Consul::API::Catalog::Impl";
}

package
    Consul::API::Catalog::Impl; # hide from PAUSE

use Moo;

use Carp qw(croak);

sub datacenters {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_catalog_endpoint."/datacenters", 'GET', %args);
}

sub nodes {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_catalog_endpoint."/nodes", 'GET', %args, sub {
        [ map { Consul::API::Catalog::ShortNode->new(%$_) } @{$_[0]} ]
    });
}

sub services {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_catalog_endpoint."/services", 'GET', %args);
}

sub service {
    my ($self, $service, %args) = @_;
    croak 'usage: $catalog->service($service, [%args])' if grep { !defined } ($service);
    $$self->_api_exec($$self->_catalog_endpoint."/service/".$service, 'GET', %args, sub {
        [ map { Consul::API::Catalog::Service->new(%$_) } @{$_[0]} ]
    });
}

sub register {
    # register
    croak "not yet implemented";
}

sub deregister {
    # deregister
    croak "not yet implemented";
}

sub node {
    my ($self, $node, %args) = @_;
    croak 'usage: $catalog->node($node, [%args])' if grep { !defined } ($node);
    $$self->_api_exec($$self->_catalog_endpoint."/node/".$node, 'GET', %args, sub {
        Consul::API::Catalog::Node->new($_[0])
    });
}

package Consul::API::Catalog::ShortNode;
$Consul::API::Catalog::ShortNode::VERSION = '0.020';
use Moo;
use Types::Standard qw(Str);

has name    => ( is => 'ro', isa => Str, init_arg => 'Node',    required => 1 );
has address => ( is => 'ro', isa => Str, init_arg => 'Address', required => 1 );

package Consul::API::Catalog::Service;
$Consul::API::Catalog::Service::VERSION = '0.020';
use Moo;
use Types::Standard qw(Str Int ArrayRef);

has name            => ( is => 'ro', isa => Str,           init_arg => 'ServiceName',    required => 1 );
has id              => ( is => 'ro', isa => Str,           init_arg => 'ServiceID',      required => 1 );
has service_address => ( is => 'ro', isa => Str,           init_arg => 'ServiceAddress', required => 1 );
has port            => ( is => 'ro', isa => Int,           init_arg => 'ServicePort',    required => 1 );
has node            => ( is => 'ro', isa => Str,           init_arg => 'Node',           required => 1 );
has address         => ( is => 'ro', isa => Str,           init_arg => 'Address',        required => 1 );
has tags            => ( is => 'ro', isa => ArrayRef[Str], init_arg => 'ServiceTags',    required => 1, coerce => sub { $_[0] || [] } );

package Consul::API::Catalog::Node;
$Consul::API::Catalog::Node::VERSION = '0.020';
use Moo;
use Types::Standard qw(HashRef);
use Type::Utils qw(class_type);

has node     => ( is => 'ro', isa => class_type('Consul::API::Catalog::ShortNode'),      init_arg => 'Node',     required => 1, coerce => sub { Consul::API::Catalog::ShortNode->new($_[0]) } );
has services => ( is => 'ro', isa => HashRef[class_type('Consul::API::Agent::Service')], init_arg => 'Services', required => 1, coerce => sub { +{ map { $_ => Consul::API::Agent::Service->new($_[0]->{$_}) } keys %{$_[0]} } } );

1;

=pod

=encoding UTF-8

=head1 NAME

Consul::API::Catalog - Catalog (nodes and services) API

=head1 SYNOPSIS

    use Consul;
    my $catalog = Consul->catalog;
    say for map { $_->name} @{$catalog->nodes};

=head1 DESCRIPTION

The catalog API is used to register and deregister nodes, services and checks.
It also provides query endpoints.

This API is fully documented at L<https://www.consul.io/docs/agent/http/catalog.html>.

=head1 METHODS

=head2 datacenters

=head2 nodes

=head2 services

=head2 service

=head2 register

=head2 deregister

=head2 node

=head1 SEE ALSO

    L<Consul>

=cut
