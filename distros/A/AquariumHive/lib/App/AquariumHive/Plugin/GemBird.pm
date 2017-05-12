package App::AquariumHive::Plugin::GemBird;
BEGIN {
  $App::AquariumHive::Plugin::GemBird::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::Plugin::GemBird::VERSION = '0.003';
use Moo;
use App::AquariumHive::Tile;
use JSON::MaybeXS;
use String::Trim;
use App::AquariumHive::Plugin::GemBird::Socket;

with qw(
  App::AquariumHive::Role
);

has sockets => (
  is => 'lazy',
);

sub _build_sockets {
  my ( $self ) = @_;
  my @lines = $self->run_cmd('sudo sispmctl -s');
  my @sockets;
  my $current;
  for (@lines) {
    unless ($current) {
      if ($_ =~ m/^Gembird #\d+$/) {
        $current = {
          app => $self->app,
        };
      }
    } else {
      if ($_ =~ m/^device type:(.+)$/) {
        $current->{device_type} = trim($1);
      } elsif ($_ =~ m/^serial number:(.+)$/) {
        $current->{serial_number} = trim($1);
      } elsif ($_ =~ m/^$/) {
        push @sockets, App::AquariumHive::Plugin::GemBird::Socket->new(%{$current});
        $current = undef;
      }
    }
  }
  return \@sockets;
}

sub BUILD {
  my ( $self ) = @_;

  $self->sockets;

  $self->on_socketio( set_power => sub {
    my ( $app, $data ) = @_;
    my %new_states;
    for my $key (keys %{$data}) {
      my $new_state = $data->{$key};
      if ($key =~ m/^([0-9a-f]+)_(\d+)$/) {
        my $socket_id = $1;
        my $no = $2;
        my ( $socket ) = grep { $_->socket_id eq $socket_id } @{$self->sockets};
        if ($socket) {
          $new_states{$socket_id.'_'.$no} = $new_state;
          $socket->set($no,$new_state);
        }
      }
    }
    if (%new_states) {
      $self->send( power => \%new_states );
    }
  });

  for my $socket (@{$self->sockets}) {
    my $socket_id = $socket->socket_id;
    my $state = $socket->state;
    for my $no (1..4) {
      my $id = $socket_id.'_'.$no;
      my $onoff = $state->{$no} ? 'ON' : 'OFF';
      $self->add_tile( 'power_'.$id, App::AquariumHive::Tile->new(
        id => 'power_'.$id,
        bgcolor => $state->{$no} ? 'green' : 'red',
        content => <<"__HTML__",

<div class="large">
  <div class="fattext">$no</div>
  <div class="fattext" id="power_val_$id">$onoff</div>
  <small>$socket_id</small>
</div>

__HTML__
        js => <<"__JS__",

\$('#power_$id').click(function(){
  var current = \$('#power_val_$id').text();
  var set_state;
  if (current == 'ON') {
    set_state = 0;
  } else {
    set_state = 1;
  }
  socket.emit('set_power',{ '$id': set_state });
});

socket.on('power', function(power){
  if ('$id' in power) {
    var onoff;
    \$('#power_$id').removeClass('bg-red').removeClass('bg-green');
    if (power['$id']) {
      onoff = 'ON';
      \$('#power_$id').addClass('bg-green');
    } else {
      onoff = 'OFF';
      \$('#power_$id').addClass('bg-red');
    }
    \$('#power_val_$id').text(onoff);    
  }
});

__JS__
      ));      
    }
  }

}

1;

__END__

=pod

=head1 NAME

App::AquariumHive::Plugin::GemBird

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
