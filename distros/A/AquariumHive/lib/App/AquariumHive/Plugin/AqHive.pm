package App::AquariumHive::Plugin::AqHive;
BEGIN {
  $App::AquariumHive::Plugin::AqHive::AUTHORITY = 'cpan:GETTY';
}
$App::AquariumHive::Plugin::AqHive::VERSION = '0.003';
use Moo;
use App::AquariumHive::Tile;
use JSON::MaybeXS;
use utf8;
use Digital qw(
  AqHive::Temp
  AqHive::ORP
  AqHive::EC
  AqHive::pH
);

with qw(
  App::AquariumHive::Role
);

use AnyEvent::JSONRPC::TCP::Client;

has kioskd_client => (
  is => 'rw',
);

sub new_kioskd_client {
  my ( $self ) = @_;
  return AnyEvent::JSONRPC::TCP::Client->new(
    host => '127.0.0.1',
    port => 24025,
    on_error => sub {
      $self->kioskd_client($self->new_kioskd_client);
    },
  );
}

our @pwm_steps = qw(
    0   1   1   2   2   2   2   2   3   3
    3   4   4   5   5   6   6   7   8   9
   10  11  12  13  15  17  19  21  23  26
   29  32  36  40  44  49  55  61  68  76
   85  94 105 117 131 146 162 181 202 225
  250 279 311 346 386 430 479 534 595 663
  739 824 918 1023
);

our %sensor_names_and_units = (
  ec => [ EC => yScm => 'yS/cm' ],
  orp => [ ORP => mV => 'mV' ],
  temp => [ Temp => C => '°C' ],
  ph => [ pH => pH => 'pH' ],
);

has pwm_step_state => (
  is => 'rw',
  default => sub {{
    1 => '0',
    2 => '0',
    3 => '0',
    4 => '0',
    5 => '0',
    6 => '0',
  }},
);

sub pwm_to_step {
  my ( $self, $pwm ) = @_;
  return 63 if $pwm >= 1023;
  my $step;
  for (0..62) {
    $step = $_ if $pwm_steps[$_] <= $pwm;
  }
  return $step;
}

sub BUILD {
  my ( $self ) = @_;

  $self->kioskd_client($self->new_kioskd_client);

  if ($self->app->simulation) {
    $self->web_mount( 'simulator', sub {
      return [ 200, [ "Content-Type" => "application/json" ], [encode_json({
        html => <<__HTML__,
<h1 class="text-center">AquariumHive 1 Simulationseinstellungen</h1>
<hr/>

__HTML__
      })] ];
    });

    $self->add_tile( 'simulator' => App::AquariumHive::Tile->new(
      id => 'simulator',
      bgcolor => 'orange',
      content => <<"__HTML__",

<div class="large">
  <div class="fattext">AqHive 1</div>
  <div class="fattext">Simulator</div>
</div>

__HTML__
      js => <<"__JS__",

\$('#simulator').click(function(){
  call_app('simulator');
});

__JS__
    ));
  }

  $self->on_data(sub {
    my ( $app, $data ) = @_;
    my %aqhive;
    for my $d (@{$data}) {
      my ( $key, $val ) = @{$d};
      my ( $sensor, $no ) = $key =~ m/^([a-zA-Z]+)(\d+)$/;
      if ($sensor_names_and_units{$sensor}) {
        my ( $name, $func, $unit ) = @{$sensor_names_and_units{$sensor}};
        $aqhive{$key} = sprintf('%.1f',input( 'aqhive_'.$sensor, $val )->$func);
      } elsif ($sensor eq 'pwm' && !$self->no_pwm) {
        $self->pwm_step_state->{$no} = $self->pwm_to_step($val);
        $aqhive{$key} = ( $self->pwm_step_state->{$no} == 63
          ? 'MAX' : $self->pwm_step_state->{$no} );
      }
    }
    $app->send( aqhive => \%aqhive );
    if ($self->sensor_rows) {
      for my $no (1..$self->sensor_rows) {
        $self->kioskd_client->call( Update => {
          name => 'values'.$no,
          type => 'text',
          text => join(' ',(
            $aqhive{'ph'.$no},'ph',
            $aqhive{'orp'.$no},'mV',
            $aqhive{'temp'.$no},'C',
            $aqhive{'ec'.$no},'yS/cm',
          )),
          x => ( 6 + ( 30 * ( $no - 1 ) ) ),
          y => 6,
          w => 1000,
          h => 30,
          font_path => '/opt/kioskd/fonts/din1451alt.ttf',
          font_point_size => 24,
          colour => [255, 255, 255, 255],
        })->cb(sub {
          eval { $_[0]->recv };
        });
      }
    }
  });

  $self->on_socketio( aqhive => sub {
    my ( $app, $data ) = @_;
    if ($data->{cmd}) {
      $app->command_aqhive($data->{cmd});
    }
  });

  if ($self->sensor_rows) {
    for my $no (1..$self->sensor_rows) {
      my $app = 'aqhive_sensors'.$no;
      $self->web_mount( $app, sub {
        return [ 200, [ "Content-Type" => "application/json" ], [encode_json({
          html => <<__HTML__,
  <h1 class="text-center">AquariumHive 1 Sensors $no</h1>
  <hr/>

__HTML__
        })] ];
      });
      for my $sensor (qw( temp ph orp ec )) {
        my $id = 'aqhive_'.$sensor.$no;
        my ( $name, $func, $unit ) = @{$sensor_names_and_units{$sensor}};
        $self->add_tile( 'aqhive_'.$sensor.$no => App::AquariumHive::Tile->new(
          id => $id,
          bgcolor => 'lightTeal',
          content => <<"__HTML__",

<div class="large">
  <div>AqHive 1</div>
  <div>$name $no</div>
  <div><span class="fattext" id="aqhive_val_$sensor$no"></span> $unit</div>
</div>

__HTML__
          js => <<"__JS__",

socket.on('aqhive', function(aqhive){
  \$('#aqhive_val_$sensor$no').text(aqhive.$sensor$no);
});

\$('#$id').click(function(){
  call_app('$app');
});

__JS__
        ));
      }    
    }
  }

  unless ($self->no_pwm) {    
    for my $pwm (1..6) {
      $self->on_socketio ( 'pwm'.$pwm, sub {
        my ( $app, $data ) = @_;
        if ($data->{cmd}) {
          my $cmd = $data->{cmd};
          if ($cmd eq 'next') {
            my $next = $self->pwm_step_state->{$pwm} + 1;
            $next = 63 if $next > 63;
            $app->command_aqhive( 'set_pwm', "".$pwm, "".$pwm_steps[$next]);
          } elsif ($cmd eq 'prev') {
            my $prev = $self->pwm_step_state->{$pwm} - 1;
            $prev = 0 if $prev < 0;
            $app->command_aqhive( 'set_pwm', "".$pwm, "".$pwm_steps[$prev]);
          } elsif ($cmd eq 'first') {
            $app->command_aqhive( 'set_pwm', "".$pwm, "0");
          } elsif ($cmd eq 'last') {
            $app->command_aqhive( 'set_pwm', "".$pwm, "1023");
          }
        }
      });
      $self->add_tile( 'aqhive_pwm'.$pwm, App::AquariumHive::Tile->new(
        id => 'aqhive_pwm'.$pwm,
        bgcolor => 'cyan',
        class => 'pwm-tile',
        content => <<"__HTML__",

<a id="aqhive_first_pwm$pwm" class="button">
  <i class="icon-first-2"></i>
</a>
<a id="aqhive_prev_pwm$pwm" class="button">
  <i class="icon-previous"></i>
</a>
<div>AqHive 1</div>
<div>PWM $pwm</div>
<div id="aqhive_val_pwm$pwm">...</div>
<a id="aqhive_next_pwm$pwm" class="button">
  <i class="icon-next"></i>
</a>
<a id="aqhive_last_pwm$pwm" class="button">
  <i class="icon-last-2"></i>
</a>

__HTML__
        js => <<"__JS__",

socket.on('aqhive', function(aqhive){
  \$('#aqhive_val_pwm$pwm').text(aqhive.pwm$pwm);
});

\$('#aqhive_prev_pwm$pwm').click(function(){
  socket.emit('pwm$pwm',{ cmd: 'prev' });
});

\$('#aqhive_next_pwm$pwm').click(function(){
  socket.emit('pwm$pwm',{ cmd: 'next' });
});

\$('#aqhive_first_pwm$pwm').click(function(){
  socket.emit('pwm$pwm',{ cmd: 'first' });
});

\$('#aqhive_last_pwm$pwm').click(function(){
  socket.emit('pwm$pwm',{ cmd: 'last' });
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

App::AquariumHive::Plugin::AqHive

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
