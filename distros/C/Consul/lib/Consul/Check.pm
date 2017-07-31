package Consul::Check;
$Consul::Check::VERSION = '0.021';
use namespace::autoclean;

use Moo::Role;
use Types::Standard qw(Str HashRef Enum);

use Carp qw(croak);

my $status_type = Enum['passing', 'warning', 'critical'];

has name       => ( is => 'ro', isa => Str, required => 1 );
has id         => ( is => 'ro', isa => Str );
has notes      => ( is => 'ro', isa => Str );
has service_id => ( is => 'ro', isa => Str );
has status     => ( is => 'ro', isa => $status_type );
has deregister_critical_service_after =>
                  ( is => 'ro', isa => Str );

sub smart_new {
  my $role = shift;
  my $args = Moo::Object->BUILDARGS( @_ );

  if (defined $args->{script}) {
    return Consul::Check::Script->new( $args );
  }
  elsif (defined $args->{ttl}) {
    return Consul::Check::TTL->new( $args );
  }
  elsif (defined $args->{http}) {
    return Consul::Check::HTTP->new( $args );
  }
  elsif (defined $args->{tcp}) {
    return Consul::Check::TCP->new( $args );
  }
  elsif (defined $args->{docker_container_id}) {
    return Consul::Check::Docker->new( $args );
  }

  croak 'Cannot create Check object because neither script, ttl, http, tcp, or docker_container_id are set';
}

sub _to_json_hash { %{shift->_json_hash} }
has _json_hash => ( is => 'lazy', isa => HashRef[Str] );
sub _build__json_hash {
    my ($self) = @_;
    {
        Name => $self->name,
        defined $self->id         ? ( ID        => $self->id         ) : (),
        defined $self->notes      ? ( Notes     => $self->notes      ) : (),
        defined $self->service_id ? ( ServiceID => $self->service_id ) : (),
        defined $self->status     ? ( Status    => $self->status     ) : (),
        defined $self->deregister_critical_service_after ? (
          DeregisterCriticalServiceAfter => $self->deregister_critical_service_after
        ) : (),
    };
}

package Consul::Check::Script;
$Consul::Check::Script::VERSION = '0.021';
use Moo;
use Types::Standard qw(Str);
use JSON::MaybeXS;

has script   => ( is => 'ro', isa => Str, required => 1 );
has interval => ( is => 'ro', isa => Str, required => 1 );

sub to_json { shift->_json }
has _json => ( is => 'lazy', isa => Str );
sub _build__json {
    my ($self) = @_;
    encode_json({
        $self->_to_json_hash,
        Script   => $self->script,
        Interval => $self->interval,
    });
}

with qw(Consul::Check);

package Consul::Check::TTL;
$Consul::Check::TTL::VERSION = '0.021';
use Moo;
use Types::Standard qw(Str);
use JSON::MaybeXS;

has ttl => ( is => 'ro', isa => Str, required => 1 );

sub to_json { shift->_json }
has _json => ( is => 'lazy', isa => Str );
sub _build__json {
    my ($self) = @_;
    encode_json({
        $self->_to_json_hash,
        TTL => $self->ttl,
    });
}

with qw(Consul::Check);

package Consul::Check::HTTP;
$Consul::Check::HTTP::VERSION = '0.021';
use Moo;
use Types::Standard qw(Str Bool);
use JSON::MaybeXS;

has http            => ( is => 'ro', isa => Str,  required => 1 );
has interval        => ( is => 'ro', isa => Str,  required => 1 );
has tls_skip_verify => ( is => 'ro', isa => Bool );

sub to_json { shift->_json }
has _json => ( is => 'lazy', isa => Str );
sub _build__json {
    my ($self) = @_;
    encode_json({
        $self->_to_json_hash,
        HTTP     => $self->http,
        Interval => $self->interval,
        defined $self->tls_skip_verify ? (
          TLSSkipVerify =>
            $self->tls_skip_verify ? \1 : \0
        ) : (),
    });
}

package Consul::Check::TCP;
$Consul::Check::TCP::VERSION = '0.021';
use Moo;
use Types::Standard qw(Str);
use JSON::MaybeXS;

has tcp      => ( is => 'ro', isa => Str, required => 1 );
has interval => ( is => 'ro', isa => Str, required => 1 );

sub to_json { shift->_json }
has _json => ( is => 'lazy', isa => Str );
sub _build__json {
    my ($self) = @_;
    encode_json({
        $self->_to_json_hash,
        TCP      => $self->tcp,
        Interval => $self->interval,
    });
}

with qw(Consul::Check);

package Consul::Check::Docker;
$Consul::Check::Docker::VERSION = '0.021';
use Moo;
use Types::Standard qw(Str);
use JSON::MaybeXS;

has docker_container_id => ( is => 'ro', isa => Str, required => 1 );
has interval            => ( is => 'ro', isa => Str, required => 1 );
has shell               => ( is => 'ro', isa => Str, required => 1 );

sub to_json { shift->_json }
has _json => ( is => 'lazy', isa => Str );
sub _build__json {
    my ($self) = @_;
    encode_json({
        $self->_to_json_hash,
        DockerContainerID => $self->docker_container_id,
        Interval          => $self->interval,
        Shell             => $self->shell,
    });
}

with qw(Consul::Check);

1;
