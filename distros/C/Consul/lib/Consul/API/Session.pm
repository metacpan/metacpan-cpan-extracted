package Consul::API::Session;
$Consul::API::Session::VERSION = '0.020';
use namespace::autoclean;

use Moo::Role;
use Types::Standard qw(Str);

requires qw(_version_prefix _api_exec);

has _session_endpoint => ( is => 'lazy', isa => Str );
sub _build__session_endpoint {
    shift->_version_prefix . '/session';
}

sub session {
    my $self = shift;
    $self = Consul->new(@_) unless ref $self;
    return bless \$self, "Consul::API::Session::Impl";
}

package
    Consul::API::Session::Impl; # hide from PAUSE

use Moo;

use Carp qw(croak);

sub create {
    my ($self, $session, %args) = @_;
    $$self->_api_exec($$self->_session_endpoint."/create", 'PUT', %args, ($session ? (_content => $session->to_json) : ()), sub {
        $_[0]->{ID}
    });
}

sub destroy {
    my ($self, $id, %args) = @_;
    croak 'usage: $session->destroy($id, [%args])' if grep { !defined } ($id);
    $$self->_api_exec($$self->_session_endpoint."/destroy/".$id, 'PUT', %args)
}

sub info {
    my ($self, $id, %args) = @_;
    croak 'usage: $session->info($id, [%args])' if grep { !defined } ($id);
    $$self->_api_exec($$self->_session_endpoint."/info/".$id, 'GET', %args,
        sub {
            return undef unless $_[0] && $_[0]->[0];
            Consul::API::Session::Session->new($_[0]->[0])
        }
    );
}

sub node {
    my ($self, $node, %args) = @_;
    croak 'usage: $session->node($id, [%args])' if grep { !defined } ($node);
    $$self->_api_exec($$self->_session_endpoint."/node/".$node, 'GET', %args, sub {
        [ map { Consul::API::Session::Session->new($_) } @{$_[0]} ]
    });
}

sub list {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_session_endpoint."/list", 'GET', %args, sub {
        [ map { Consul::API::Session::Session->new($_) } @{$_[0]} ]
    });
}

sub renew {
    my ($self, $id, %args) = @_;
    croak 'usage: $session->renew($id, [%args])' if grep { !defined } ($id);
    $$self->_api_exec($$self->_session_endpoint."/renew/".$id, 'PUT', %args, sub {
        Consul::API::Session::Session->new($_[0]->[0])
    });
}

package Consul::API::Session::Session;
$Consul::API::Session::Session::VERSION = '0.020';
use Moo;
use Types::Standard qw(Str Enum ArrayRef Num Int);

has id           => ( is => 'ro', isa => Str,                      init_arg => 'ID',          required => 1 );
has name         => ( is => 'ro', isa => Str,                      init_arg => 'Name',        required => 1 );
has behavior     => ( is => 'ro', isa => Enum[qw(release delete)], init_arg => 'Behavior',    required => 1 );
has ttl          => ( is => 'ro', isa => Str,                      init_arg => 'TTL',         required => 1 );
has node         => ( is => 'ro', isa => Str,                      init_arg => 'Node',        required => 1 );
has checks       => ( is => 'ro', isa => ArrayRef[Str],            init_arg => 'Checks',      required => 1 );
has lock_delay   => ( is => 'ro', isa => Num,                      init_arg => 'LockDelay',   required => 1 );
has create_index => ( is => 'ro', isa => Int,                      init_arg => 'CreateIndex', required => 1 );

1;

=pod

=encoding UTF-8

=head1 NAME

Consul::API::Session - Sessions API

=head1 SYNOPSIS

    use Consul;
    my $session = Consul->session;

=head1 DESCRIPTION

The Session API is used to create, destroy, and query sessions.

This API is fully documented at L<https://www.consul.io/docs/agent/http/session.html>.

=head1 METHODS

=head2 create

=head2 destroy

=head2 info

=head2 node

=head2 list

=head2 renew

=head1 SEE ALSO

    L<Consul>

=cut
