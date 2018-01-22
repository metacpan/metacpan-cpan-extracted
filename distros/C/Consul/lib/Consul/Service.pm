package Consul::Service;
$Consul::Service::VERSION = '0.023';
use namespace::autoclean;

use Moo;
use Types::Standard qw(Str Int Bool ArrayRef);
use Carp qw(croak);
use JSON::MaybeXS;

has name                => ( is => 'ro', isa => Str,           required => 1 );
has id                  => ( is => 'ro', isa => Str );
has address             => ( is => 'ro', isa => Str );
has port                => ( is => 'ro', isa => Int );
has tags                => ( is => 'ro', isa => ArrayRef[Str], default => sub { [] } );
has script              => ( is => 'ro', isa => Str );
has interval            => ( is => 'ro', isa => Str );
has ttl                 => ( is => 'ro', isa => Str );
has enable_tag_override => ( is => 'ro', isa => Bool,          default => sub { 0 } );

sub BUILD {
    my ($self) = @_;

    my $A = defined $self->script;
    my $B = defined $self->interval;
    my $C = defined $self->ttl;

    croak "Invalid check arguments, required: script, interval OR ttl"
        unless (!$A && !$B && !$C) || ($A && $B && !$C) || (!$A && !$B && $C)
}

sub to_json { shift->_json }
has _json => ( is => 'lazy', isa => Str );
sub _build__json {
    my ($self) = @_;
    encode_json({
        Name => $self->name,
        defined $self->id        ? ( ID       => $self->id       ) : (),
        defined $self->port      ? ( Port     => $self->port     ) : (),
        defined $self->address   ? ( Address  => $self->address  ) : (),
        Tags => $self->tags,
        defined $self->script    ? ( Script   => $self->script   ) : (),
        defined $self->interval  ? ( Interval => $self->interval ) : (),
        defined $self->ttl       ? ( TTL      => $self->ttl      ) : (),
        EnableTagOverride => ($self->enable_tag_override ? \1 : \0),
    });
}

1;
