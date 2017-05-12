package AquariumHive::Simulator;
BEGIN {
  $AquariumHive::Simulator::AUTHORITY = 'cpan:GETTY';
}
$AquariumHive::Simulator::VERSION = '0.003';
use Moo;
use AnyEvent::Handle;
use AnyEvent::Util 'portable_socketpair';
use HiveJSO;
use DDP;

sub BUILD {
  my ( $self ) = @_;
  $self->handle;
  $self->pulse;
}

has _portable_socketpair => (
  is => 'lazy',
  init_arg => undef,
);

sub _build__portable_socketpair {
  my ($fh1, $fh2) = portable_socketpair;
  return [ $fh1, $fh2 ];
}

has handle => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_handle {
  my ( $self ) = @_;
  my $handle = AnyEvent::Handle->new(
    fh => $self->_portable_socketpair->[1],
  );
  $handle->on_read(sub {
    $_[0]->push_read( hivejso => sub {
      my ( $handle, $data ) = @_;
      if (ref $data eq 'HiveJSO::Error') {
        p($data->error); p($data->garbage);
        return;
      }
      $self->on_hivejso($data);
    });
  });
  return $handle;
}

has fh => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_fh {
  my ( $self ) = @_;
  return $self->_portable_socketpair->[0];
}

has sensor_rows => (
  is => 'lazy',
);

sub _build_sensor_rows { 2 }

has pulse => (
  is => 'lazy',
);

sub _build_pulse {
  my ( $self ) = @_;
  return unless $self->sensor_rows;
  return AE::timer 0, 60, sub {
    for my $no (1..$self->sensor_rows) {
      for my $sensor (qw( ph orp ec temp )) {
        my $attr = $sensor.$no;
        my $next = 'next_'.$sensor;
        my $current = $self->state->{$attr};
        my $new = $self->$next($current);
        $self->state->{$attr} = $new;
      }
    }
  };
}

has state => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_state {
  my ( $self ) = @_;
  return {
    (map { 'pwm'.$_, 0 } (1..6)),
    (map { 'ph'.$_, $self->next_ph } (1..$self->sensor_rows)),
    (map { 'orp'.$_, $self->next_orp } (1..$self->sensor_rows)),
    (map { 'ec'.$_, $self->next_ec } (1..$self->sensor_rows)),
    (map { 'temp'.$_, $self->next_temp } (1..$self->sensor_rows)),
  };
}

sub hivejso_base {
  return unit => 'aqhive';
}

sub state_to_hivejso {
  my ( $self ) = @_;
  my %state = %{$self->state};
  my @data;
  for my $key (keys %state) {
    push @data, [$key, $state{$key}];
  }
  return HiveJSO->new( $self->hivejso_base, data => \@data );
}

sub on_hivejso {
  my ( $self, $hivejso ) = @_;
  if ($hivejso->has_command) {
    # "o":"data"
    if ($hivejso->command_cmd eq 'data') {
      $self->send_state;
    }
    # "o":["set_pwm1",100]
    if ($hivejso->command_cmd eq 'set_pwm') {
      my ( $no, $value ) = $hivejso->command_args;
      my $func = 'pwm'.$no;
      $self->state->{$func} = $value;
      $self->send_state;
    }
  }
}

sub send_state {
  my ( $self ) = @_;
  $self->handle->push_write($self->state_to_hivejso->hivejso_short);
}

sub next_temp {
  my ( $self, $current ) = @_;
  return 615 unless defined $current;
  my $new = $current + (int(rand(3)) - 2);
  return $self->next_temp($current) if $new > 619 || $new < 610;
  return $new;
}

sub next_ph {
  my ( $self, $current ) = @_;
  return 512 unless defined $current;
  my $new = $current + (int(rand(5)) - 3);
  return $self->next_ph($current) if $new > 525 || $new < 500;
  return $new;
}

sub next_orp {
  my ( $self, $current ) = @_;
  return 458 unless defined $current;
  my $new = $current + (int(rand(5)) - 3);
  return $self->next_orp($current) if $new > 475 || $new < 425;
  return $new;
}

sub next_ec {
  my ( $self, $current ) = @_;
  return 120 unless defined $current;
  my $new = $current + (int(rand(5)) - 3);
  return $self->next_ec($current) if $new > 140 || $new < 100;
  return $new;
}

1;

__END__

=pod

=head1 NAME

AquariumHive::Simulator

=head1 VERSION

version 0.003

=head1 DESCRIPTION

B<IN DEVELOPMENT, DO NOT USE YET>

See L<http://aquariumhive.com/> for now.

=head1 SUPPORT

IRC

  Join #AquariumHive on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  https://github.com/homehivelab/aquariumhive
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/homehivelab/aquariumhive/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
