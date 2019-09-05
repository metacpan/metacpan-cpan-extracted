package Consul::API::ACL;
$Consul::API::ACL::VERSION = '0.026';
use namespace::autoclean;

use Moo::Role;
use Types::Standard qw(Str);

requires qw(_version_prefix _api_exec);

has _acl_endpoint => ( is => 'lazy', isa => Str );
sub _build__acl_endpoint {
    shift->_version_prefix . '/acl';
}

sub acl {
    my $self = shift;
    $self = Consul->new(@_) unless ref $self;
    return bless \$self, "Consul::API::ACL::Impl";
}

package
    Consul::API::ACL::Impl; # hide from PAUSE

use Moo;

use Carp qw(croak);
use Scalar::Util qw( blessed );
use Consul::ACL;

sub create {
    my ($self, $acl, %args) = @_;
    $acl ||= {};
    $acl = Consul::ACL->new($acl) if !blessed $acl;
    $$self->_api_exec($$self->_acl_endpoint."/create", 'PUT', %args, _content => $acl->to_json(), sub{
        Consul::API::ACL::Success->new($_[0])
    });
}

sub update {
    my ($self, $acl, %args) = @_;
    croak 'usage: $acl->update($acl, [%args])' if grep { !defined } ($acl);
    $acl = Consul::ACL->new($acl) if !blessed $acl;
    $$self->_api_exec($$self->_acl_endpoint."/update", 'PUT', %args, _content => $acl->to_json());
}

sub destroy {
    my ($self, $id, %args) = @_;
    croak 'usage: $acl->destroy($id, [%args])' if grep { !defined } ($id);
    $$self->_api_exec($$self->_acl_endpoint."/destroy/$id", 'PUT', %args);
}

sub info {
    my ($self, $id, %args) = @_;
    croak 'usage: $acl->info($id, [%args])' if grep { !defined } ($id);
    $$self->_api_exec($$self->_acl_endpoint."/info/$id", 'GET', %args, sub {
        Consul::API::ACL::Info->new($_[0]->[0])
    });
}

sub clone {
    my ($self, $id, %args) = @_;
    croak 'usage: $acl->clone($id, [%args])' if grep { !defined } ($id);
    $$self->_api_exec($$self->_acl_endpoint."/clone/$id", 'PUT', %args, sub{
        Consul::API::ACL::Success->new($_[0])
    });
}

sub list {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_acl_endpoint."/list", 'GET', %args, sub {
        [ map { Consul::API::ACL::Info->new($_) } @{$_[0]} ]
    });
}

package Consul::API::ACL::Info;
$Consul::API::ACL::Info::VERSION = '0.026';
use Moo;
use Types::Standard qw(Str);

has create_index => ( is => 'ro', isa => Str, init_arg => 'CreateIndex', required => 1 );
has modify_index => ( is => 'ro', isa => Str, init_arg => 'ModifyIndex', required => 1 );
has id           => ( is => 'ro', isa => Str, init_arg => 'ID',          required => 1 );
has name         => ( is => 'ro', isa => Str, init_arg => 'Name',        required => 1 );
has type         => ( is => 'ro', isa => Str, init_arg => 'Type',        required => 1 );
has rules        => ( is => 'ro', isa => Str, init_arg => 'Rules',       required => 1 );

package Consul::API::ACL::Success;
$Consul::API::ACL::Success::VERSION = '0.026';
use Moo;
use Types::Standard qw(Str);

has id           => ( is => 'ro', isa => Str, init_arg => 'ID',          required => 1 );

1;

=pod

=encoding UTF-8

=head1 NAME

Consul::API::ACL - Access control API

=head1 SYNOPSIS

    use Consul;
    my $acl = Consul->acl;

=head1 DESCRIPTION

The ACL API is used to create, update, destroy, and query ACL tokens.

This API is fully documented at L<https://www.consul.io/docs/agent/http/acl.html>.

=head1 METHODS

=head2 create

=head2 update

=head2 destroy

=head2 info

=head2 clone

=head2 list

=head1 SEE ALSO

    L<Consul>

=cut
