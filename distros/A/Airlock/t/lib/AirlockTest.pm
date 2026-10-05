package AirlockTest;

# Shared fixture: an Airlock with a settable clock, a recorded event log and
# direct access to the in-process store.

use strict;
use warnings;
use Airlock;
use Airlock::Store::Memory;

sub new {
  my ( $class, %arg ) = @_;
  my $self = bless { clock => 1_000_000, events => [], memory => Airlock::Store::Memory->new }, $class;
  $self->{airlock} = Airlock->new(
    clients => {
      cli  => { name => 'Test CLI', scopes => [qw( read write admin )] },
      open => {}
    },
    verification_uri => 'https://example.org/airlock',
    store            => $self->{memory}->as_subs,
    now              => sub { $self->{clock} },
    on_event         => sub { push @{ $self->{events} }, $_[0] },
    %arg
  );
  return $self;
}

sub airlock { $_[0]{airlock} }
sub memory  { $_[0]{memory} }
sub events  { $_[0]{events} }
sub clock   { $_[0]{clock} }

sub advance {
  my ( $self, $seconds ) = @_;
  return $self->{clock} += $seconds;
}

sub event_names { [ map { $_->{event} } @{ $_[0]{events} } ] }

sub start {
  my ( $self, %arg ) = @_;
  return $self->airlock->open( client_id => 'cli', scope => 'read', %arg )->data;
}

sub row {
  my ( $self, $device_code ) = @_;
  return $self->memory->find( 'hash', $self->airlock->code->hash($device_code) );
}

1;
