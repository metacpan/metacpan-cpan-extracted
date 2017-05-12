package Audio::Radio::XM::PCR;

### This is the radio.  This represents the radio and should be a "copy of the radio"
### Use this just like you would use a radio with features like 
### power
### tune
### mute
### The user shouldn't have to know anything about how the radio works in order to use this.



use 5.008003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Radio::XM::PCR ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


my $is_windows;
if ($^O =~ /Win32/) {
    $is_windows = 1;
} else {
    $is_windows = 0;
}

if ($is_windows) {
    require Win32::SerialPort;
} else {
    require Device::SerialPort;
}

my $channel_cache_timeout = 30;

my $channels = {};

my $response_codes = { # Power Settings
                       '80' => 'power_on',
                       '81' => 'power_off',
                       # Basic Confirmation
                       '90' => 'channel_changed',
                       '93' => 'mute_set',
                       # Channel info
                       'a2' => 'ext_channel_info',
                       'a5' => 'channel_info',
                       #Idenxtification
                       'b1' => 'radio_id',
                       # Technical
                       'c3' => 'signal_quality',
                       # Monitor 
                       'd0' => 'label_changed',
                       'd1' => 'channel_name_changed',
                       'd2' => 'genre_changed',
                       'd3' => 'artist_title_changed',
                       'd4' => 'artist_changed',
                       'd5' => 'title_changed',
                       'd6' => 'song_time_changed',
                       # Activation
                       'e0' => 'activated',
                       'e1' => 'deactivated',
                       # Error
                       'ff' => 'fatal_error'};


my $responses = { 'power_on'              =>  {'reponse_octet'     => '80',
                                               'unpack_template'   => 'H2 H2 H2 H2 H2 H4 C H2 C H2 H2 H2 H2 H4 H2 A8 C',
                                               'unpack_method'     => '_read_power',
                                               'on_trigger_method' => ''},
                  'power_off'             =>  {'reponse_octet'     => '81',
                                               'unpack_template'   => 'H4',
                                               'unpack_method'     => '_read_power',
                                               'on_trigger_method' => '',},
                  'channel_changed'       =>  {'reponse_octet'     => '90',
                                               'unpack_template'   => 'H2 C C H2',
                                               'unpack_method'     => '_read_channel',
                                               'on_trigger_method' => ''},
                  'mute_set'              =>  {'reponse_octet'     => '93',
                                               'unpack_template'   => 'H2 C C C',
                                               'unpack_method'     => '_read_mute',
                                               'on_trigger_method' => ''},
                  'ext_channel_info'      =>  {'reponse_octet'     => 'A2',
                                               'unpack_template'   => 'H2 C H2 A32 H2 A38 H2 H*',
                                               'unpack_method'     => '_read_channel',
                                               'on_trigger_method' => ''},
                  'channel_info'          =>  {'reponse_octet'     => 'A5',
                                               'unpack_template'   => 'H2 C C H2 A16 H4 A16 H2 A16 A16 H2 H*',
                                               'unpack_method'     => '_read_channel',
                                               'on_trigger_method' => ''},
                  'radio_id'              =>  {'response_octet'    => 'B1',
                                               'unpack_template'   => 'H2 A9 H',
                                               'unpack_method'     => '_read_radio_id',
                                               'on_trigger_method' => ''},
                  'signal_quality'        =>  {'response_octet'    => 'C3',
                                               'unpack_template'   => 'H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2 H2',
                                               'unpack_method'     => '_read_signal_strength',
                                               'on_trigger_method' => ''},
                  'activated'             =>  {'reponse_octet'     => 'e0',
                                               'unpack_template'   => 'H2',
                                               'unpack_method'     => '_read_activated',
                                               'on_trigger_method' => '',},
                  'deactivated'           =>  {'reponse_octet'     => 'e1',
                                               'unpack_template'   => 'H2',
                                               'unpack_method'     => '_read_activated',
                                               'on_trigger_method' => '',},
                  'label_changed'         =>  {'reponse_octet'     => 'd0',
                                               'unpack_template'   => 'H2',
                                               'unpack_method'     => '_read_mon_label',
                                               'on_trigger_method' => '',},
                  'channel_name_changed'  =>  {'reponse_octet'     => 'd1',
                                               'unpack_template'   => 'H2',
                                               'unpack_method'     => '_read_mon_channel',
                                               'on_trigger_method' => '',},
                  'genre_changed'         =>  {'reponse_octet'     => 'd2',
                                               'unpack_template'   => 'H2',
                                               'unpack_method'     => '_read__mon_genre',
                                               'on_trigger_method' => '',},
                  'artist_title_changed'  =>  {'reponse_octet'     => 'd3',
                                               'unpack_template'   => 'H2 A16 A16 H2 H2',
                                               'unpack_method'     => '_read_mon_artist_title',
                                               'on_trigger_method' => '',},
                  'artist_changed'        =>  {'reponse_octet'     => 'd4',
                                               'unpack_template'   => 'H2',
                                               'unpack_method'     => '_read_mon_artist_title',
                                               'on_trigger_method' => '',},
                  'title_changed'         =>  {'reponse_octet'     => 'd5',
                                               'unpack_template'   => 'H2',
                                               'unpack_method'     => '_read_mon_artist_title',
                                               'on_trigger_method' => '',},
                  'song_time_changed'     =>  {'reponse_octet'     => 'd6',
                                               'unpack_template'   => 'H2 H2 H2 CC CC CC',
                                               'unpack_method'     => '_read_mon_song_time',
                                               'on_trigger_method' => '',},
                  'fatal_error'           =>  {'response_octet'    => 'FF',
                                               'unpack_template'   => 'A*',
                                               'unpack_method'     => '_read_fatal_error',
                                               'on_trigger_method' => ''}
                };


my $command_start = ['5A', 'A5'];
my $command_end   = ['ED', 'ED'];
my $commands      = {'on'                  => ['00', '10', '10', '24', '01'],
                     'off'                 => ['01', '00'],
                     'sleep'               => ['01', '01'],
                     'channel_change'      => ['10', '02', 'CHANNEL', '00', '00', '01'],
                     'mute_on'             => ['13', '01'],
                     'mute_off'            => ['13', '00'],
                     'ext_channel_info'    => ['22', 'CHANNEL'],
                     'this_channel_info'   => ['25', '08', 'CHANNEL', '00'],
                     'next_channel_info'   => ['25', '09', 'CHANNEL', '00'],
                     'radio_id'            => ['31'],
                     'signal_quality'      => ['43'],
                     'monitor'             => ['50', 'CHANNEL', '01', '01', '01', '01']
                     };

# Preloaded methods go here.

### Constructor
sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {'channels'        => { '1' => {'name'         => 'Preview',
                                             'genre'        => 'Preview',
                                             'artist'       => 'Preview',
                                             'title'        => 'Preview',
                                             'enabled'      => 1,
                                             'start_time'   => 0,
                                             'end_time'     => 0,
                                             'last_update'  => 0}},
              'power'           => 'unknown',
              'activated'       => 'unknown',
              'signal'          => {'sat1'         => 0,
                                    'sat2'         => 0,
                                    'terr'         => 0,
                                    'last_update'  => 0},
              'technical'       => {'radio_id'     => ''},
              'mute'            => 'unknown',
              'current_channel' => 1,
              'full_refresh'    => {'last_update'  => 0,
                                    'completed'    => 0}
            };
  bless $self, $class;

  return $self;
}

##### Private Stuff

sub _close_port {
  my $self = shift;

  if ($self->port_state eq 'Open') {
    $self->{_radio}->close;
    undef $self->{_radio};
  }
  $self->port_state('Closed');
  return $self;  
}

sub _write_port {
  my $self = shift;
  my $command  = shift;
  my $channel = shift;
  my $rct = shift || 50;

  my @msg;

  # Copy from the master hash - don't mess up the master!
  foreach my $value (@{$commands->{$command}}) {
    push @msg, $value;
  }

  unshift @msg, sprintf("%04d", scalar(@msg));

  # Set the channel
  @msg = map ( /CHANNEL/ ? sprintf("%02X", $channel) : $_, @msg);
  
  unshift @msg, @$command_start;
  push @msg, @$command_end;
  my $message = join('', @msg);

  $self->{_radio}->write(pack("H*", $message));
  $self->{_radio}->read_const_time($rct);
}

sub _read_port {
  my $self  = shift;
  
  my $radio = $self->{_radio};
  
  my $count;      
  my $reply; 
  
  # Read the header first
  ($count, $reply) = $radio->read(6);
  if ($count) { 
    # Lop off the 0x5a & 0xa5      
    $reply = substr($reply,2);
    # Grab the length and code
    my $length = (unpack("C", substr($reply, 0, 1)) * 256) + unpack("C", substr($reply, 1, 1));
    my $code = unpack("H*",substr($reply, 2, 1));
    ($count, $reply) = $radio->read($length);
    if ($count == $length) {
      return ($code, $reply);
    } else {
      return;
    }
  }
  return;
}

sub _read {
  my $self = shift;
  my $query = shift;
  while (my ($code, $result) = $self->_read_port) {
    my $response_code = $response_codes->{$code};
    my $unpack_template = $responses->{$response_code}->{'unpack_template'};
    my $unpack_method = $responses->{$response_code}->{'unpack_method'};
    my $on_trigger_method =  $responses->{$response_code}->{'on_trigger_method'};
    my @params = unpack($unpack_template, $result);

    $self->$unpack_method($code,@params);

    if (ref($on_trigger_method) ne "") {
      &{$on_trigger_method};
    }
  }
}

sub _write {
  my $self = shift;

  return $self->_write_port(@_);
}

sub _open_port {
    my $self = shift;
    my $port_handle;

    if ($is_windows) {
        $port_handle = new Win32::SerialPort ("$self->{_device}")
        || die "Can't open Serial Port! ($self->{_device} $!\n";
    } else {
        $port_handle = new Device::SerialPort ("$self->{_device}")
        || die "Can't open USB Port! ($self->{_device} $!\n";
    }
    if (!defined $port_handle) {
      return 0;
    }
      
    $port_handle->baudrate(9600);
    $port_handle->parity("none");
    $port_handle->databits(8);
    $port_handle->stopbits(1);
    $port_handle->handshake("none");
    $port_handle->write_settings;

    if (1) { # Should test to see if it's really open and talking...
      $self->{_radio} = $port_handle;
      $self->port_state('Open');
      return 1;
    } else {
      $self->port_state('Closed');
      return 0;
    }
    return 1;
}

sub _monitor {
  my $self = shift;
  my $reps = shift || 1;
  my $count = 0;
  # Check to see if there's anything waiting on the pipe
  while (++$count <= $reps) {
    $self->_read();
  }
}
### Private Reader Methods
sub _read_power {
  my $self = shift;
  my $code = shift;
  my @params = @_;

  if ($code eq '80') {
    my $last_channel = {'audio' => $params[6],
                        'data'  => $params[8]};

    $self->{'power'} = 'on';
    $self->{'current_channel'} = $last_channel->{'audio'};
    $self->{'technical'}->{'SDEC'}  = { 'version' => $params[2],
                                        'date'    => $params[3] . '-' . $params[4] . '-' . $params[5]};
    $self->{'technical'}->{'XMSTK'} = { 'version' => $params[10],
                                        'date'    => $params[11] . '-' . $params[12] . '-' . $params[13]};
    $self->{'technical'}->{'radio_id'} = $params[15];

    return 1;
  } elsif ($code eq '81') {
    $self->{'power'} = 'off';
    return 1;
  } else {
    return 0;
  }
}

sub _read_activated {
  my $self = shift;
  my $code = shift;
  my @params = @_;

  if ($code eq 'e0') {
    $self->{'activated'} = 'yes';
  } elsif ($code eq 'e1') {
    $self->{'activated'} = 'no';
  } else {
    return 0;
  }
  return 1;
}

sub _read_channel {
  my $self = shift;
  my $code = shift;
  my @params = @_;
  
  if ($code eq '90') {
    $self->{'current_channel'} = $params[1];
    $self->{'current_service'} = $params[2];
    
  } elsif ($code eq 'a2') {
    # Do Nothing - The ext_channel_info doesn't work yet.
  } elsif ($code eq 'a5') {
    my $channel = $params[1];
    if ($channel == 0) {
      $self->{'full_refresh'}->{'completed'} = 1;
      $self->{'full_refresh'}->{'last_updated'} = time();
    }

    $self->{'channels'}->{$channel}->{'service_id'}  = $params[2];
    $self->{'channels'}->{$channel}->{'channel'}     = $channel;
    $self->{'channels'}->{$channel}->{'name'}        = $params[4];
    $self->{'channels'}->{$channel}->{'genre'}       = $params[6];
    $self->{'channels'}->{$channel}->{'artist'}      = $params[8];
    $self->{'channels'}->{$channel}->{'title'}       = $params[9];
    $self->{'channels'}->{$channel}->{'enabled'}     = 1;
    $self->{'channels'}->{$channel}->{'last_update'} = time();
  } else {
    return 0;
  }
  return 1;
}

sub _read_mute {
  my $self = shift;
  my $code = shift;
  my @params = @_;

  if ($code eq '93') {
    if ($params[1]) {
      $self->{'mute'} = '1';
    } else {
      $self->{'mute'} = '0';
    }
  } else {
    return 0;
  }
  return 1;
}

sub _read_radio_id {
  my $self = shift;
  my $code = shift;
  my @params = @_;

  if ($code eq 'b1') {
    $self->{'technical'}->{'radio_id'} = $params[1];
  } else {
    return 0;
  }
  return 1;
}



sub _read_signal_strength {
  my $self = shift;
  my $code = shift;
  my @params = @_;
  my $levels = {'00' => 'Poor',
                '01' => 'Fair',
                '02' => 'Good',
                '03' => 'Excellent'};

# Populate the hash
  $self->{'signal_strength'} = {'sat'  => {'quality' => $levels->{$params[1]},
                                           '1'       => {'demod' => $params[3],
                                                         'TDM'   => $params[6],
                                                         'BER'   => $params[9],
                                                         'AGC'   => $params[12],
                                                         'CN'    => $params[14]},
                                           '2'       => {'demod' => $params[4],
                                                         'TDM'   => $params[7],
                                                         'BER'   => $params[10],
                                                         'AGC'   => $params[13],
                                                         'CN'    => $params[15]}},
                                'terr' => {'quality' => $levels->{$params[2]},
                                           '1'       => {'demod' => $params[5],
                                                         'TDM'   => $params[8],
                                                         'BER'   => $params[11]}}};
# Calculate others
# Percentages
# Satellite
  my @sat_db;
  $sat_db[1] = $self->{'signal_strength'}->{'sat'}->{'1'}->{'CN'} / 4;
  $sat_db[2] = $self->{'signal_strength'}->{'sat'}->{'2'}->{'CN'} / 4;

  $self->{'signal_strength'}->{'sat'}->{'1'}->{'db'} = $sat_db[1];
  $self->{'signal_strength'}->{'sat'}->{'2'}->{'db'} = $sat_db[2];

  for (my $x=1; $x<=2; $x++) {
    if ($sat_db[$x] < 12) {
      $self->{'signal_strength'}->{'sat'}->{$x}->{'percent'} = $sat_db[$x] * 80 / 12;
    } elsif ($sat_db[$x] < 16) {
      $self->{'signal_strength'}->{'sat'}->{$x}->{'percent'} = ((($sat_db[$x] - 48) * 20 / 4) + 80);
    } else {
      $self->{'signal_strength'}->{'sat'}->{$x}->{'percent'} = 99.9;
    }
  }
# Terrestrial
  my $terr_signal = $self->{'signal_strength'}->{'terr'}->{1}->{'BER'} / 68;

  $terr_signal = 100 - ($terr_signal * 10);

  if ($terr_signal <= 0) {
    $terr_signal = 0;
  } elsif ($terr_signal >= 100) {
    $terr_signal = 100;
  }

  $self->{'signal_strength'}->{'terr'}->{1}->{'percent'} = $terr_signal;

# Summary Information
  if ($self->{'signal_strength'}->{'sat'}->{'1'}->{'db'} > $self->{'signal_strength'}->{'sat'}->{'2'}->{'db'}) {
    $self->{'signal_strength'}->{'sat'}->{'db'} = $self->{'signal_strength'}->{'sat'}->{'1'}->{'db'};
    $self->{'signal_strength'}->{'sat'}->{'percent'} = $self->{'signal_strength'}->{'sat'}->{'1'}->{'percent'};
  } else {
    $self->{'signal_strength'}->{'sat'}->{'db'} = $self->{'signal_strength'}->{'sat'}->{'2'}->{'db'};
    $self->{'signal_strength'}->{'sat'}->{'percent'} = $self->{'signal_strength'}->{'sat'}->{'2'}->{'percent'};
  }
  $self->{'signal_strength'}->{'terr'}->{'percent'} = $self->{'signal_strength'}->{'terr'}->{'1'}->{'percent'};
}

sub _read_mon_song_time {
  my $self = shift;
  my $code = shift;
  my @params = @_;
  
  if ($code eq 'd6') {
    my $current_time = time;
    my $total_duration = $params[3]*256 + $params[4];
    my $used_duration = $params[5]*256 + $params[6];
    my $remain_duration = $total_duration - $used_duration;
    my $start = $current_time - $used_duration;
    my $end = $start + $total_duration;
    $self->{'channels'}->{$self->{'current_channel'}}->{'start_time'}  = $start;
    $self->{'channels'}->{$self->{'current_channel'}}->{'end_time'}    = $end;
    $self->{'channels'}->{$self->{'current_channel'}}->{'duration'}    = $total_duration;
    $self->{'channels'}->{$self->{'current_channel'}}->{'remaining'}   = $remain_duration;
    $self->{'channels'}->{$self->{'current_channel'}}->{'last_update'} = $current_time;
  } else {
    return 0;
  }
  return 1;
}

sub _read_mon_artist_title {
  my $self = shift;
  my $code = shift;
  my @params = @_;
  
  if ($code eq 'd3') {
    $self->{'channels'}->{$self->{'current_channel'}}->{'artist'}      = $params[1];
    $self->{'channels'}->{$self->{'current_channel'}}->{'title'}       = $params[2];
    $self->{'channels'}->{$self->{'current_channel'}}->{'enabled'}     = 1;
    $self->{'channels'}->{$self->{'current_channel'}}->{'last_update'} = time();
  } else {
    return 0;
  } 
  return 1;
}
sub _read_mon_label {
  return 1;
}

sub _read__mon_genre {
  return 1;
}

sub _read_mon_channel {
  return 1;
}

sub _read_monitored_data {
  return 1; 
}

sub _read_fatal_error {
  my $self = shift;
  my $code = shift;
  my @params = @_;

  ### Can't really do anything about it...
  return 1;
}

### Stuff that the user can do - Public methods

sub open {
  my $self = shift;
  $self->connect;
  $self->power('on');
  $self->tune(1);
  $self->mute('off');
}

sub close {
  my $self = shift;
  $self->connect;
  $self->power('off');
}

## Connect/Disconnect/Port Actions
sub connect {
  my $self = shift;
  my %args = @_;

  $self->open_port(%args);
}

sub open_port {
    my $self = shift;
    my %args = @_;
    if ($self->port_state() eq 'Open') {
      return 1;
    } else {
      if (defined ($args{device})) {
        $self->{_device} = $args{device};
      } else {
        if ($is_windows) {
          $self->{_device} = 'COM5';
        } else {
          $self->{_device} = '/dev/ttyUSB0';
        }
      }
      return $self->_open_port();
    }
  }

sub close_port {
  my $self = shift;
  return $self->_close_port;
}

sub port_state {
    my $self = shift;
    my $val  = shift;

    if (!defined($self->{'_port_state'})) {
      $self->{'_port_state'} = 'Closed';
    }

    $self->{_port_state} = $val if (defined($val));

    return $self->{_port_state};
}

sub command {
  my $self = shift;
  my $command = shift;
  my $channel = shift;

  $self->_write($command, $channel);
  $self->_monitor;
}
   


sub set_trigger {
  my $self=shift;
  my $action = shift;
  my $sub = shift;
 
  $responses->{$action}->{'on_trigger_method'} = $sub;

}

sub get_trigger {
  my $self = shift;
  my $action = shift;
  return $responses->{$action}->{'on_trigger_method'};
}

sub monitor {
  my $self=shift;
  my $current_channel = $self->{'current_channel'};

  #get any old stuff
  $self->_monitor();
  
}

sub full_refresh {
  my $self = shift;
  my $current_channel = $self->{'current_channel'};

  $self->{'full_refresh'}->{'completed'} = 0;
  
  # clear the flags
  foreach my $channel (keys %{$self->{'channels'}}) {
    if ($channel != $current_channel) {
      $self->{'channels'}->{$channel}->{'last_update'} = 0;
    }
  }
  # Iterate - We're out of sync so make a guess
  my $last_channel = 1;
  while ($self->{'full_refresh'}->{'completed'} == 0) {
    for (my $channel = 1; $channel < 256; $channel++) {
      next if $channel == $current_channel;
      next if !defined $self->{'channels'}->{$channel};
      next if $self->{'channels'}->{$channel}->{'last_update'} == 0;
      $last_channel = $channel;
    }
    $self->command('next_channel_info', $last_channel);
    $self->_monitor;
  }
  $self->{'last_full_refresh'} = time;
  $self->command('monitor', $current_channel);
}

### --Power--
### Turn on or off the power
### power(action) where action is:
### on - Power On
### off - Power Off
### sleep - Power Saving Mode
sub power {
  my $self = shift;
  my $command = lc(shift);

  if (!defined $command || $command eq 'on') {
    $command = 'on';
  } elsif ($command ne 'off' && $command ne 'sleep') {
    return -1;
  }

  $self->command($command);  
  while($self->{'power'} ne $command) {
    $self->monitor();
  }
}

### --Mute--
### Mute the sound
### mute(action) where action is:
### on - silence the radio
### off - allow the sound to play
sub mute {
  my $self = shift;
  my $op = lc(shift);
  
  my $command;
  
  if (!defined $op || $op eq 'on') {
    $command = 'mute_on';
  }
  elsif ($op eq 'off') {
    $command = 'mute_off';
  } else {
    return -1;
  }    
  $self->command($command);
}

### --Tune--
### Change the channel
### tune(channel) where channel is the new channel
### note that this not only tunes the channel, but it also sets up for the monitoring loop
sub tune {
  my $self = shift;
  my $channel = shift;

  # Is the channel valid?
  if (!defined $channel ||
      $channel < 1 ||
      $channel > 256) {
    return;
  }
  
  # Change the channel
  $self->command('channel_change', $channel);
  $self->get_channel_info($channel);

  $self->command('monitor', $channel);
  while ($self->{'current_channel'} != $channel) {
    $self->_monitor;
  }
  return 1;
}

### Get Data

# --- get_current_channel ---
# Returns: channel_hash
sub get_current_channel {
  my $self = shift;
  my $channel = $self->{'current_channel'};
  if (defined $self->{'channels'}->{$channel}) {
    # I'm assuming that the current channel is COMPLETELY up to date
    return $self->{'channels'}->{$channel};
  } else {
    return $self->get_channel_info($channel);
  }
} 

# --- get_channel_info ---
# Args: channel
# Returns: channel_hash
sub get_channel_info {
  my $self = shift;
  my $channel = shift;

  if ($channel eq "") {
    # You should have called get_current_channel
    return $self->get_current_channel();
  }

  if ($channel > 256 ||
      $channel < 1) {
    return;
  }
  my $channel_hash = $self->{'channels'}->{$channel};
  if ($self->command('this_channel_info',$channel)) {
    $self->command('ext_channel_info', $channel);
    return $self->{'channels'}->{$channel};
  }
}

sub get_next_channel_info {
  my $self = shift;
  my $channel = shift;

  if ($channel > 256 ||
      $channel < 1) {
    return;
  }

  my $channel_hash = $self->{'channels'}->{$channel};
  if ($self->command('next_channel_info',$channel)) {
    return $self->{'channels'}->{$channel};
  }
}

sub get_radio_id {
  my $self = shift;
  if ($self->{'technical'}->{'radio_id'} eq '') {
    $self->command('radio_id');
  }
  return $self->{'technical'}->{'radio_id'};
}


sub get_signal_quality {
  my $self = shift;
  $self->command('signal_quality');
  return $self->{'signal_strength'};
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!
#The format of the commands is:

# 5A A5 00 = START COMMAND STRING
# XX  = Length of the command
# ZZ ZZ ZZ ZZ ... = The command and arguments

# Commands are:
# 00 - Power On
# 01 - Power Off
# 10 - Change Channels
# 13 - Set Mute
# 31 - Get Radio ID

### Power On (00 16 16 24 01)
### Returns Returns 33/40 Bytes; 33 = Not Activated.  40 = Activated.
# 1 00 = POWER ON COMMAND
# 2 16 = Channel Label Size (8,10, or 16)
# 3 16 = Channel Category Size (8, 10, or 16)
# 4 24 = Artist & Title Size (8, 10, 16, 24)
# 5 01 = Radio Type (00 = Constant Power ; 01 = Power Not Constant)

### Power Off (01 01)
### Returns - Nothing
# 1 01 = POWER OFF COMMAND
# 2 00 = Power Off Type (00 = Off Mode; 01 = Sleep Mode)

### Change Channels 
### Returns 12 Bytes?
# 1 10 = CHANNEL CHANGE COMMAND
# 2 02 = Selection Method (Select Method?)
# 3 01 = Channel Number (hex)
# 4 00 = Format (00 = Audio; 01 = Data)
# 5 00 = Program Type
# 6 01 = Routing (01 =  Audio Port)

### Mute
### Returns 10 bytes
# 1 13 = MUTE COMMAND
# 2 01 = Mute On/Off (00 = Off; 01 = On)

### Channel Info
### Returns 83 Bytes
# 1 25 = CHANNEL LIST COMMAND
# 2 08 = Selection Method (8: Label Channel Select)
#                         (9: Label Channel Next)
# 3 XX = Channel Number (hex, 00 = all)
# 4 00 = Program Type (?)
# EDED = END COMMAND STRING

### Radio ID
### Returns 
# 1 31 = RADIO ID COMMAND

### Tech Info
### Returns 32 Bytes
# 1 43 = TECH COMMAND

### Monitor Current Channel
### Returns ???
# 1 50 = MONITOR LABEL CHANGE COMMAND
# 2 XX = Channel Number (Service or Channel?)
# 3 XX = Service (1 = Yes; 0 = No) 
# 4 XX = Program (1 = Yes; 0 = No)
# 5 XX = Info (1 = Yes; 0 = No)
# 6 XX = Extended Info (1 = Yes; 0 = No)

=head1 NAME

Audio::Radio::XM::PCR - Perl extension for the XM PCR Radio

=head1 SYNOPSIS



  use Audio::Radio::XM::PCR;
  my $radio = new Audio::Radio::XM::PCR;

  $radio->open;

  # Basic
  $radio->tune(8);  

  # Listen For a while
  sleep(900);

  # Advanced 
  $radio->set_trigger('artist_title_changed', \&print_info);

  # Run for an hour
  my $time = time;
  my $end_time = $time + 3600;

  while (1) {
    my $now = time;
    if ($now > $end_time) {
      last;
    }
    $radio->monitor;
  } 

  $radio->close;

  sub print_info {
    my $channel = $radio->{'current_channel'};
    my $artist = $radio->{'channels'}->{$channel}->{'artist'};
    my $title  = $radio->{'channels'}->{$channel}->{'title'};
    my $length = $radio->{'channels'}->{$channel}->{'remaining'};
    my $minutes = int $length/60;
    my $seconds = $length % 60;
    print "$channel $artist - $title - $minutes:$seconds";
  }


=head1 DESCRIPTION

The XM PCR Radio is a USB serial device.

=head1 TODO

=over 4

=item Fully documented.  There are methods to get back the signal strength, etc. - But they're not documented

=back

=head1 BUGS

=over 4

=item Weirdness - After running for a long time, I'm seeing some undefined string errors.

=back

=head1 SEE ALSO

We use the following modules:
  Device::SerialPort - Unix/Linux
  Win32::SerialPort  - Windows

=head1 AUTHOR

Peter Bowen, E<lt>peter-radio@bowenfamily.orgE<gt>

Special thanks to others who figured out the protocol.  I'm definately standing 
on the shoulders of giants.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Peter Bowen

XM, XM Direct, and PCR are trademarks of XM Sattelite Radio.
Windows is a trademark of Microsoft Corp.

Use of this library may be limited by the XM Service and Subscription Terms
availalble at http://www.xmradio.com/get_xm/customer_service.html.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
