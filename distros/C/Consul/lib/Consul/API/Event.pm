package Consul::API::Event;
$Consul::API::Event::VERSION = '0.023';
use namespace::autoclean;

use Moo::Role;
use Types::Standard qw(Str);

requires qw(_version_prefix _api_exec);

has _event_endpoint => ( is => 'lazy', isa => Str );
sub _build__event_endpoint {
    shift->_version_prefix . '/event';
}

sub event {
    my $self = shift;
    $self = Consul->new(@_) unless ref $self;
    return bless \$self, "Consul::API::Event::Impl";
}

package
    Consul::API::Event::Impl; # hide from PAUSE

use Moo;

use Carp qw(croak);

sub fire {
    my ($self, $name, %args) = @_;
    croak 'usage: $event->fire($name, [%args])' if grep { !defined } ($name);
    my $payload = delete $args{payload};
    $$self->_api_exec($$self->_event_endpoint."/fire/".$name, 'PUT', %args, ($payload ? (_content => $payload) : ()), sub {
        Consul::API::Event::Event->new($_[0])
    });
}

sub list {
    my ($self, %args) = @_;
    $$self->_api_exec($$self->_event_endpoint."/list", 'GET', %args, sub {
        [ map { Consul::API::Event::Event->new(%$_) } @{$_[0]} ]
    });
}

package Consul::API::Event::Event;
$Consul::API::Event::Event::VERSION = '0.023';
use Convert::Base64 qw(decode_base64);

use Moo;
use Types::Standard qw(Str Int Maybe);

has id             => ( is => 'ro', isa => Str,        init_arg => 'ID',            required => 1 );
has name           => ( is => 'ro', isa => Str,        init_arg => 'Name',          required => 1 );
has payload        => ( is => 'ro', isa => Maybe[Str], init_arg => 'Payload',       required => 1, coerce => sub { defined $_[0] ? decode_base64($_[0]) : undef});
has node_filter    => ( is => 'ro', isa => Str,        init_arg => 'NodeFilter',    required => 1 );
has service_filter => ( is => 'ro', isa => Str,        init_arg => 'ServiceFilter', required => 1 );
has tag_filter     => ( is => 'ro', isa => Str,        init_arg => 'TagFilter',     required => 1 );
has version        => ( is => 'ro', isa => Int,        init_arg => 'Version',       required => 1 );
has l_time         => ( is => 'ro', isa => Int,        init_arg => 'LTime',         required => 1 );

1;

=pod

=encoding UTF-8

=head1 NAME

Consul::API::Event - User event API

=head1 SYNOPSIS

    use Consul;
    my $event = Consul->event;

=head1 DESCRIPTION

The Event API is used to fire new events and to query the available events.

This API is fully documented at L<https://www.consul.io/docs/agent/http/event.html>.

=head1 METHODS

=head2 fire

=head2 list

=head1 SEE ALSO

    L<Consul>

=cut
