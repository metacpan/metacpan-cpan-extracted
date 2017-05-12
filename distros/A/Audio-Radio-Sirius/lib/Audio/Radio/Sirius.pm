package Audio::Radio::Sirius;

use 5.008;

use warnings;
use strict;

use Carp;
use Time::HiRes qw(sleep); # need to sleep for milliseconds in some receive loops

=head1 NAME

Audio::Radio::Sirius - Control a Sirius satellite radio tuner

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
our $AUTOLOAD;

our %DEFAULTS = (
	power 	=> 0,
	connected	=> 0,
	channel	=> 0,
	gain		=> 0,
	debug		=> 0,
	mute		=> 0,
	verbosity	=> 0,
	_sequence	=> 0,
	_serial	=> undef,
	_lastack	=> -1,
	_lastreq	=> -1,
	_callbacks	=> {
		'channel_update'	=> undef,
	},
	_buffer	=> '',
);

our %SETTABLE = (
	debug		=> 1,
);

our %COMMANDS = (
	poweroff		=> '000800',
	reset			=> '0009',
	poweron		=> '000803',
	volume		=> '0002',
	mute			=> '0003',
	channel		=> '000a', channel_suffix	=> '000b',
	request_signal	=> '4018',
	request_unkn1	=> '4017',
	request_sid		=> '4011',
	verbosity		=> '000d000000'
);

our %UPDATES = (
	'2008' 	=> {
		name		=> 'power',
		handler	=> undef
	},
	'2002'	=> {
		name		=> 'volume',
		handler	=> undef
	},
	'2003'	=> {
		name		=> 'mute',
		handler	=> undef
	},
	'200a'	=> {
		name		=> 'channel',
		handler	=> \&_channel_update,
		removefirst	=> 4
	},
	'200d'	=> {
		name		=> 'verbosity',
		handler	=> undef
	},
	'6011'	=> {
		name		=> 'reply_sid',
		handler	=> undef
	},
	'6017'	=> {
		name		=> 'reply_unkn1',
		handler	=> undef
	},
	'6018'	=> {
		name		=> 'reply_signal',
		handler	=> undef
	},
	'8001'	=> {
		name		=> 'channel_info',
		handler	=> \&_channel_item_update,
		removefirst	=> 2
	},
	'8002'	=> {
		# The way verbosity works now, we won't see PID info.  Verbosity must not include channel updates or it only sends those
		# (mostly because PIDs are part of channel updates).
		name		=> 'pid_info',
		handler	=> undef,
	},
	'8003'	=> {
		name		=> 'time_info',
		handler	=> \&_time_update,
		removefirst	=> 2
	},
	'8004'	=> {
		# 1 1 0 - acquiring signal
		# 1 0 0 - all's well
		# 2 1 0 - antenna disconnected
		# 2 0 1 - antenna back
		name		=> 'tuner_info',
		handler	=> undef,
		removefirst	=> 2
	},
	'8005'	=> {
		name		=> 'signal_info',
		handler	=> \&_signal_update,
		removefirst	=> 2
	},
);

our %TYPES = (
	command	=> '00',
	ack		=> '80',
	e_busy	=> '82',
	e_checksum	=> '83'
);

our %ITEM_TYPES = (
	0x1	=> 'artist',
	0x2	=> 'title',
	0x6	=> 'composer',
	0x86	=> 'pid'
);


our $START = 'a40300'; # Const that prefaces each command

=head1 SYNOPSIS

Sirius satellite radio (L<http://www.sirius.com>) is a US based satellite radio serice.  While none of the tuners they make have serial or USB connectors,
it has been found that generation 2.5 tuners (Sportster, Starmate, * Replay, Sirius Connect, and others) have a common tuner module.  Furthermore
this tuner module generally has a serial interface.  Presently only one commercial site is offering a modification for adding a serial port to a 
Sirius tuner: L<http://www.rush2112.net>.  Google should reveal schematics and parts needed for adding ports to other tuners.

Once your tuner is connected to your system and accessible via a serial port like device, you can use this module to access it:

  use Audio::Radio::Sirius;
  use Win32::SerialPort; # or Device::SerialPort on Linux

  my $serial = new Win32::SerialPort('com1');
  my $tuner = new Audio::Radio::Sirius;

  $tuner->connect($serial);
  $tuner->power(1);
  $tuner->channel(184); # tune in the preview channel

=head1 CONSTRUCTOR

=head2 new 

Call new to create an instance of the Sirius radio object.  Once the object is created, you will probably want to L<connect|/"connect (serialport object)"> to it.

=cut

 sub new {
 	my $class = shift;
	my $self = { %DEFAULTS };
	bless $self, $class;
 	return $self;
 }

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or croak "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://; # Remove Audio::Radio::Sirius:: bit

	unless (exists $self->{$name}) { croak "$name is not a field in class $type"; }

	if (@_) {
		# setter
		if (defined($SETTABLE{$name}) ) { return $self->{$name} = shift; }
		else { croak "$name cannot be changed."; }
	} else {
		return $self->{$name};
	}
}

sub DESTROY {
	my $self = shift;

	if (defined($self->{_serial} )) {
		$self->{_serial}->close;
		undef $self->{_serial};
	}
}

=head1 OBJECT METHODS

=head2 connect (serialport object)

Connect establishes a connection between the tuner object and the SerialPort object.  The SerialPort
object must be a Win32::SerialPort or a Device::SerialPort.

  require Win32::SerialPort;
  
  my $serial_port = new Win32::SerialPort('com1');

  $tuner->connect($serial_port);

=cut

sub connect {
	my $self = shift;
	if (!ref($self)) { croak "$self isn't an object"; }
	my ($connection) = @_;
	my $connectiontype = ref($connection);

	### TODO: switch to isa() here to allow derived classes
	if (($connectiontype eq "Win32::SerialPort")
		|| ($connectiontype eq "Device::SerialPort")) {
		$connection->baudrate(57600);
		$connection->parity('none');
		$connection->databits(8);
		$connection->stopbits(1);
		$connection->handshake('none');
#		$connection->read_const_time(150);
#		$connection->read_interval(50);
#		$connection->read_char_time(10);
#		$connection->write_char_time(10);
#		$connection->read_const_time(1000);
#		$connection->read_interval(5);
#		$connection->read_char_time(50);
#		$connection->write_char_time(0);
		if (!$connection->write_settings) {
			carp "Couldn't open connection: $_";
			return 0;
		}
		$self->{_serial} = $connection;
#		$self->_send_command($COMMANDS{'reset'});
#		if ( !$self->_send_command($COMMANDS{'poweroff'}) ) {
#			carp "Tuner didn't respond to poweroff command";
#			return 0;
#		}
		$self->{connected} = 1; # we're live
		return 1;
	} else {
		croak "Connect needs a Win32::SerialPort or a Device::SerialPort, got a $connectiontype";
	}
}

=head2 power (state)

Use to turn the radio on (1) or off (0).  Returns true if succeeded.

  $tuner->power(1); # Power on tuner.

=cut

sub power {
### TODO: Needs accessor and turn off method
	my $self = shift;
	if (!ref($self)) { croak "$self isn't an object"; }
	my ($powerreq) = @_;

	if (!defined($powerreq)) { return $self->{'power'}; }
	if ($powerreq == 1) {
		my $current_gain = $self->{gain};
		my $current_mute = $self->{mute};
		if (!(
			$self->_send_command($COMMANDS{'reset'}) &&
			$self->_send_command($COMMANDS{'poweroff'}) &&
			$self->_send_command($COMMANDS{'poweron'}) &&
#			$self->_send_command('000c0000001700') && #useless
			$self->gain($current_gain) &&
			$self->_send_command($COMMANDS{'request_signal'}) &&
			$self->_send_command($COMMANDS{'request_sid'}) &&
			$self->mute($current_mute)
#			$self->{'power'} = 1
		)) {
			carp "Error - tuner failed to respond to power-up sequence.";
			return 0;
		}
	} else {
		$self->_send_command($COMMANDS{'poweroff'});
		$self->{'power'} = 0;
	}
}

=head2 gain (db)

Gain ranges from -9db to 0db.  It defaults to 0.  When called with a parameter, gain returns 
false on failure and true on success.  When called without a parameter, gain returns the current gain
setting.

  $tuner->gain(-6); # Mom's on the phone, turn down Howard Stern

  my $current_gain = $tuner->gain;

=cut

sub gain {
	my $self = shift;
	if (!ref($self)) { croak "$self isn't an object"; }

	my ($gainreq) = @_;

	if (!defined($gainreq)) { return $self->{gain}; } # accessor

	# mutator
	if (!($gainreq <= 0) && ($gainreq >= -9)) {
		carp "Requested gain out of range: $gainreq.  Must be between -9 and 0.";
		return 0;
	}

	my $gainhex = $self->_num_to_signed_hex($gainreq);
	my $cmd = $COMMANDS{volume}.$gainhex;
	
	if (!$self->_send_command($cmd)) {
		carp "Tuner did not respond to gain setting.";
		return 0;
	}
	return 1;
}

=head2 mute (mute setting)

When called with a parameter, you can set it to 1 to mute and 0 to unmute.  Called without a parameter
retrieves the current setting.

  my $result = $tuner->mute(0); # Unmute the tuner

  my $muted = $tuner->mute;

=cut

sub mute {
	my $self = shift;
	if (!ref($self)) { croak "$self isn't an object"; }

	my ($mutereq) = @_;

	if (!defined($mutereq)) { return $self->{mute}; } # accessor

	if (!( ($mutereq == 0) || ($mutereq == 1) ) ) {
		carp "Mute must be either 0 or 1.";
		return 0;
	}

	my $mutehex = $self->_num_to_signed_hex($mutereq);
	my $cmd = $COMMANDS{'mute'} . $mutehex;
	if (!$self->_send_command($cmd)) {
		carp "Tuner did not respond to mute command.";
		return 0;
	}

	return 1;
}

=head2 channel (channel number, offset)

Can be used without a parameter to get the current channel number or with a parameter to change channels.  When used with a parameter, returns true 
on success and false on failure.  Offset is -1 to select the channel before the specified number, 1 to select the channel above the specified number,
or 0 (default) to simply go to the specified channel.

  my $current_channel = $tuner->channel;

  my $result = $tuner->channel(6, 1); # Tune to channel 7

  $tuner->channel(100); # Tune directly to channel 100

=cut
sub channel {
	my $self = shift;
	if (!ref($self)) { croak "$self isn't an object"; }

	my ($chanreq, $offsetreq) = @_;
	my $offset = 0;

	if (!defined($chanreq)) { return $self->{channel}; } # accessor
	if (defined($offsetreq) && ($offsetreq =~ /0|1|-1/) ) { $offset = $offsetreq; }

	### TODO: Channel validation.

	# channel command: $COMMAND, channel, [0,1,-1], $COMMAND suffix
	my $chanhex = $self->_num_to_unsigned_hex($chanreq);
	my $offsethex = $self->_num_to_signed_hex($offset);
	my $cmd = $COMMANDS{channel} . $chanhex . $offsethex . $COMMANDS{channel_suffix};
	return $self->_send_command($cmd);	
}

=head2 monitor (cycles)

Monitor is called to watch for updates from the tuner.  The Sirius tuner is pretty chatty and sends relevant data, such as Artist/Title updates, 
PIDs, signal strength, and other information.  Calling monitor initiates reads of this data.

Reads happen automatically when commands are executed (for example changing the channel or muting the tuner).  Still, monitor generally needs
to be called as often as possible to gather the latest data from the Tuner.

A monitor cycle will take a minimum of one second.  If data is received, this timer resets.  In other words, monitor may take longer than you anticipate.
The amount of time monitor takes will depend on the C<verbosity> of the tuner.

If no number of cycles is specified, monitor runs one cycle.

B<Note:> As of version 0.02, the cycle parameter is no longer a true count of the number of cycles.  The number specified is multiplied by 20.
Each cycle now sleeps 50 msec so the result is roughly the same, although this may increase the drift of cycles vs. seconds even more.

  $tuner->monitor(5); # spin 5 times

=cut

sub monitor {
	my $self = shift;
	if (!ref($self)) { croak "$self isn't an object"; }

	my ($spins) = @_;

	if (!defined($spins)) { $spins = 1; }
	$spins = $spins * 20;
	foreach (1..$spins) {
		$self->_receive_if_waiting;
		sleep (.05); # chill .05 second
	}
}

=head2 set_callback (callback type, function reference)

When the tuner sends an update, such as new artist/title information on the current channel, it may be helpful to execute some code which handles this
event.  To accomidate this, you may define function callbacks activated when each event occurs.  Note that some of the parameters below are marked with 
an asterisk.  This indicates that they may be undefined when your function is called.  You should account for this in your callback function.

=head3 channel_update (channel, *pid, *artist, *title, *composer)

 $tuner->set_callback ('channel_update', \&channel);

 sub channel {
	my ($channel, $pid, $artist, $title, $composer) = @_;
	print "Channel $channel is now playing $title.\n";
 }

=head3 signal_update

Not yet implemented.

=head3 time_update

Not yet implemented.

=head3 status_update

Not yet implemented.

=cut

sub set_callback {
	my $self = shift;
	if (!ref($self) eq 'CODE') { croak "$self isn't an object"; }
	my ($reqtype, $funcref) = @_;
	if (!ref $funcref) { croak "$funcref must be a reference to a function"; }
	if (!exists($DEFAULTS{'_callbacks'}{$reqtype}) ) { croak "$reqtype is not a supported update type"; }
	# validated enough for 'ya??

	$self->{'_callbacks'}{$reqtype} = $funcref;
}

=head2 verbosity (level)

Not to be confused with C<debug>, verbosity changes the updates the tuner sends.  By default, the tuner only sends updates for artist/title/PID
on the current channel.  The Generation 2.5 tuners can send artist/title on all channels, the current time, signal strength, and PID information on all 
channels.

Internally the tuner treats verbosity as a bitmap allowing you to control each type of update you are interested in.  For now, this module treats it
as a boolean.  0 (default) requests that no updates be sent.  1 requests that all of the following updates are sent:

=over

=item *

Artist/Title information for every channel

=item *

PID information for every channel

=item *

Signal strength

=item *

Current time

=back

  $tuner->verbosity(1); #request all of these updates
  $current_verbosity=$tuner->verbosity;

=cut

sub verbosity {
	my $self = shift;
	if (!ref($self)) { croak "$self isn't an object"; }
	my ($verbreq) = @_;

	if (!defined($verbreq)) { return $self->{verbosity}; } # accessor
	if ($verbreq == 0) {
		# 0 = no verbosity, 1b = full verbosity
		my $cmd = $COMMANDS{verbosity}.'0000';
		$self->_send_command($cmd);
		$self->{verbosity} = $verbreq;
	}
	if ($verbreq == 1) {
		# 0 = no verbosity, 1b = full verbosity
#		my $cmd = $COMMANDS{verbosity}.'1b00';
		my $cmd = $COMMANDS{verbosity}.'1f00';
		$self->_send_command($cmd);
		$self->{verbosity} = $verbreq;
	}
}

sub _read {
	# _read works like read from $serial.  except better.
	# returns ($count, $data)
	# the tests for > 200000 check for the get_tick_count function wrapping
	# (happens every 43 days or something)
	my $self = shift;
	my ($count) = @_;
	my $debug = $self->{debug};
	my $serial = $self->{_serial};
	my $buffer = $self->{_buffer};
	my $buffer_count = length($buffer);

	my $data = '';
	my $data_count = 0;

	my $timeout = 100;
	my $start_ticks = $serial->get_tick_count;
	my $end_ticks = $start_ticks + $timeout;
	WAIT: while ( (($serial->status)[1] == 0) && ($buffer_count==0) ) { # loop while nothing is waiting
		if (($serial->get_tick_count > $end_ticks) || (($end_ticks - $serial->get_tick_count) > 200000)) {
			# last WAIT;
			return 0, $data; 
		}
		sleep .005;
		#print "hi $buffer_count\n";
	}

	# READ: while (($serial->status)[1] > 0) { # loop while data is waiting
	do {
		my $input = '';
		if ($buffer_count > 0) {
			$input = $buffer;
			$self->{_buffer} = '';
			$buffer_count = 0;
		}
		$input .= $serial->input;
		my $input_count = length($input);
		if ($input_count > 0) {
			$data .= $input;
			$data_count += $input_count;
			$end_ticks += 6; # bonus delay because we got something
		}
		sleep .001;
		#print "$data_count: $count\n";
	} until (($data_count >= $count) || ($serial->get_tick_count > $end_ticks) || 
		(($end_ticks - $serial->get_tick_count) > 200000)); 

	if ($data_count > $count) {
		$self->{_buffer} = substr($data, $count);
		return $count, substr($data, 0, $count);
	}
	#print "returning: $data\n";
	return $data_count, $data;
}

sub _receive_if_waiting {
	my $self = shift;
	if (!ref($self)) { croak "$self isn't an object"; }

	my $serial = $self->{_serial};
	my $waiting = ($serial->status)[1];
	if (defined($waiting) && $waiting > 6) { $self->_receive; }
}

sub _receive {
	my $self = shift;
	my $serial = $self->{_serial};
	my $debug = $self->{debug};
	READ: while (1) {
		#my ($headercount, $header) = $serial->read(6);
		my ($headercount, $header) = $self->_read(6);
		last READ if ($headercount == 0);
		if ($headercount < 6) {
			if ($debug) { 
				my $hexheader = $self->_pformat($header);
				print "Read error: headercount is $headercount: $hexheader\n"; 
			}
			next READ;
		}

		# handle escape escape in header (mostly)
		my $headerescapes  = $header =~ s/\x1b\x1b/\x1b/g;
		if ($headerescapes) { 
			# read even more
			if ($debug) { print "Fixing $headerescapes escape characters in header.\n"; }
			#my ($headercount2, $header2) = $serial->read($headerescapes);
			my ($headercount2, $header2) = $self->_read($headerescapes);
			next READ if ($headercount2 < $headerescapes); # :(
			$header .= $header2;
		}

		my ($start, $seq, $type, $length) = unpack('H6C1H2C1', $header);

		next READ if ($start ne $START); # oy
		
		# there's a special case that happens if length = 1b (the escape character).  we need to read 1 just to flush it.
		if ($length == 0x1b) {
			if ($debug) { print "Length 1b.  Flushing 1 character.\n"; }
			#$serial->read(1);
			$self->_read(1);
		}

		#my ($datacount, $data) = $serial->read($length+1); # read data and checksum
		my ($datacount, $data) = $self->_read($length+1); # read data and checksum
		next READ if ($datacount < $length + 1); # shouldn't happen
		# everything was read.
		# handle the escape character in the data sequence.  must be done before checksum.
		my $escapecount = $data =~ s/\x1b\x1b/\x1b/g;
		FIXESC: if ($escapecount) { 
			# read even more
			if ($debug) { print "Fixing $escapecount escape characters.\n"; }
			#my ($datacount2, $data2) = $serial->read($escapecount);
			my ($datacount2, $data2) = $self->_read($escapecount);
			next READ if ($datacount2 < $escapecount); # :(
			$data .= $data2;
			$escapecount = $data =~ s/\x1b\x1b/\x1b/g;
			if ($escapecount) { redo FIXESC; } # for the special times when we read more data due to escape chars and the data we read contains them... ugh
		}
		if ($debug >= 3) {print '<< '.$self->_pformat($header . $data)."\n"; }
		my $checksum = chop $data;
		my $calculated = $self->_checksum($header . $data);
		if ($calculated ne $checksum) {
			my ($calcval, $realval) = (ord($calculated), ord($checksum) );
			if ($debug) { print "Checksum didn't match - calc: $calcval act: $realval\n"; }
			$self->_send_checksum_error($seq);
			next READ; # this is also bad news :(
		}

		# start processing for real
		if ($type eq $TYPES{ack}) {
			$self->{_lastack} = $seq;
			if ($debug) { print "Got an ack for seq: $seq\n"; }
			next READ;
		}

		# ack it now before we go further.  the tuner is impatient.
		$self->_send_ack($seq);

		if ($type eq $TYPES{command}) {
			# did we get this already?
			if ($seq == $self->{_lastreq}) {
				# Tuner is repeating itself... This is bad.
				if ($debug > 2) { print "Not handling duplicate update seq $seq\n"; }
				next READ;
			}
			$self->{_lastreq} = $seq;
			# handle the update, then send an ack
			my $updatetype = unpack ('H4', $data);
			if (defined($UPDATES{$updatetype})) {
				# OK... I recognize this update.
				my $updatename = $UPDATES{$updatetype}{name};
				my $updatehandler = $UPDATES{$updatetype}{handler};
				if ($debug) {
					print "Received an update: $updatename\n";
				}
				if (defined($updatehandler)) {
					# some responses are identical but the identical part starts
					# somewhere after the command...  chop it off to the identical bits
					my $removefirst = $UPDATES{$updatetype}{removefirst};
					$data=substr($data,$removefirst);
					$self->$updatehandler($data);
				}
					
			} else {
				# unknown command.
				if ($debug) {
					my $datahex = $self->_pformat($data);
					print "Unknown update: $updatetype data: $datahex\n";
				}
			}
		}
	}
}

sub _channel_update {
	my $self = shift;
	my ($data) = @_;
	
	my ($channel, $categorynum, $shortchan, $longchan, $shortcat, $longcat);
	($channel, $categorynum, $shortchan, $longchan, $shortcat, $longcat, $data) = unpack ('C1xC1xxC1/aC/aC/aC/aa*', $data);

	$self->{channel} = $channel;

	$self->{categories}{$categorynum}{longname} = $longcat;
	$self->{categories}{$categorynum}{shortname} = $shortcat;
	$self->{channels}{$channel}{longname} = $longchan;
	$self->{channels}{$channel}{shortname} = $shortchan;

	$self->{channels}{$channel}{category} = $self->{categories}{$categorynum};
	$self->{categories}{$categorynum}{channels}{$channel} = $self->{channels}{$channel};

	# process left over items
	$self->_channel_items($channel, $data);

	# call handler
	$self->_call_channel_handler($channel);
}

sub _call_channel_handler {
	my $self = shift;
	my ($channel) = @_;

	# update handler: ($channel, $pid, $artist, $title, $composer)
	my $handler = $self->{'_callbacks'}{'channel_update'};
	if (ref($handler)) {
		&$handler (
			$channel,
			$self->{'channels'}{$channel}{'pid'},
			$self->{'channels'}{$channel}{'artist'},
			$self->{'channels'}{$channel}{'title'},
			$self->{'channels'}{$channel}{'composer'}
		);
	}
}

sub _signal_update {
	my $self = shift;
	my ($data) = @_;
	my $debug = $self->{debug};

	my ($overall, $sat, $terrestrial) = unpack ('CCC', $data);

	foreach my $signal ($overall, $sat, $terrestrial) {
		$signal = $signal * .33;
	}
	if ($debug>1) { print "Signal overall: $overall Sat: $sat Terrestrial: $terrestrial\n"; }
	$self->{signal}{overall} = $overall;
	$self->{signal}{sat} = $sat;
	$self->{signal}{terrestrial} = $terrestrial;
}

sub _time_update {
	my $self = shift;
	my ($data) = @_;
	my $debug = $self->{debug};

	my ($year, $month, $day, $hour, $minute, $second) = unpack ('nCCCCC', $data);
	if ($debug>1) { print "Time update: $year-$month-$day $hour:$minute:$second\n"; }

	# send to user functions as reverse list to conform with perl custom
}

sub _channel_item_update {
	my $self = shift;
	my ($data) = @_;

	my $channel;
	($channel, $data) = unpack ('C1a*', $data);
	$self->_channel_items($channel, $data);

	# call handler
	$self->_call_channel_handler($channel);
}

sub _channel_items {
	# multiple updates contain this stuff.  call this with $chan and $data.
	my $self = shift;
	my ($channel, $data) = @_;
	my $debug=$self->{debug};


	my $numitems;
	($numitems, $data) = unpack ('C1a*', $data);
	if ($numitems>0) {
		# there be items here
		# step 1 - clean out the old items
		foreach my $clean (values %ITEM_TYPES) {
			$self->{channels}{$channel}{$clean} = undef;
		}

		ITEM: foreach (1..$numitems) {
			my ($itemtype, $item, $typevar);
			($itemtype, $item, $data) = unpack ('C1C1/aa*', $data);
			$typevar = $ITEM_TYPES{$itemtype};
			if ($debug > 1) { print "Item type: $itemtype Info: $item\n"; }
			if (!defined($typevar)) {
				if ($debug) { print "Channel update contained unrecognized item: $itemtype: $item\n"; }
				next ITEM;
			}
			# store item
			$self->{channels}{$channel}{$typevar} = $item;
		}
	}
	my $remainder = length($data);
	if ($remainder > 0) { warn "Got a remainder when reading channel update."; }
}

sub _send_ack {
	my $self = shift;
	my ($seq) = @_;

	my $rawdata = pack('H6C1H2C1', $START, $seq, $TYPES{ack}, 0);
	my $checksum = $self->_checksum($rawdata);
	my $data = $rawdata.$checksum;
	if ($self->debug >= 3) {print '>> '.$self->_pformat($data)."\n"; }

	my $serial = $self->{_serial};
	my $count_out = $serial->write($data);
	warn "Not enough data written" unless ($count_out == length($data));
}

sub _send_checksum_error {
	my $self = shift;
	my ($seq) = @_;

	my $rawdata = pack('H6C1H2C1', $START, $seq, $TYPES{e_checksum}, 0);
	my $checksum = $self->_checksum($rawdata);
	my $data = $rawdata.$checksum;
	if ($self->debug >= 3) {print '>> '.$self->_pformat($data)."\n"; }

	my $serial = $self->{_serial};
	my $count_out = $serial->write($data);
	warn "Not enough data written" unless ($count_out == length($data));
}

sub _send_command {
	### TODO: Handle escape char (1B)
	# returns true/false results
	my $self = shift;
	my ($hexcommand) = @_;
	my $command = pack('H*', $hexcommand);
	my $cmdlength = length($command);
	my $sequence = $self->{_sequence};

	my $rawdata = pack('H6C1H2C1a*', $START, $sequence, $TYPES{command}, $cmdlength, $command);
	my $checksum = $self->_checksum($rawdata);
	# oddly enough the double escapes don't count as length.  don't change original length.
	my $data = pack('H6C1H2C1a*a1', $START, $sequence, $TYPES{command}, $cmdlength, $command, $checksum);

	# handle the escape character anywhere in the sent data.  must be done after checksum.
	$data =~ s/\x1b/\x1b\x1b/g;

	my $serial = $self->{_serial};

	my $attempts=0;
	SEND: foreach $attempts (1..5) {
		# send/retry logic
		if ($self->{debug}) { print "Sending command: $hexcommand sequence: $sequence\n"; }
		if ($self->debug >= 3) {print '>> '.$self->_pformat($data)."\n"; }
		$serial->write($data);
		$self->_receive;
		last SEND if ($self->{_lastack} == $sequence );
		# we're still here...  receiver is probably busy.  give it a bit.
		sleep(3);
	}

	$self->{_sequence} = ($self->{_sequence} + 1);
	if ($self->{_sequence} > 255) { $self->{_sequence} = 0; }
	
	if (($attempts == 3) && ($self->{lastack} != $sequence) ) {
		carp "Command not acknowledged by tuner after 3 attempts.";
		return 0;
	}
	return 1;
}


sub _checksum {
	# returns 1 byte (char) of checksum data
	# i can replace this with unpack.  just need to do the 256-result thing.
	# is there a bug here when $sum % 256 = 0?
	my $self = shift;
	my ($data) = @_;

	my $char;
	my $sum = 0;
	foreach $char (split(//, $data)) {
		$sum += ord($char);
	}
	if ( ($sum % 0x100) == 0) { return chr(0); }
	my $cs = 0x100 - ($sum % 0x100);
	return chr($cs);
}

sub _pformat {
	my $self = shift;
	my ($data) = @_;
	my $buffer = '';

	my $char;

	foreach $char (split(//, $data)) {
		$char = ord($char);
		if (($char >= 32) && ($char <= 126)) {
#			$buffer .= chr($char);
			$buffer .= sprintf ("0x%02x ", $char);
		} else {
			$buffer .= sprintf ("0x%02x ", $char);
		}
	}
	return $buffer;
}

sub _num_to_signed_hex {
	my $self = shift;
	my ($data) = @_;

	return (unpack('H2', pack ('c1', $data) ) );
}

sub _num_to_unsigned_hex {
	my $self = shift;
	my ($data) = @_;

	return (unpack('H2', pack ('C1', $data) ) );
}

=head1 DEPENDENCIES

None yet.

=head1 AUTHOR

Jamie Tatum, L<http://thelightness.blogspot.com>, C<< <jtatum@gmail.com> >>

=head1 BUGS

=over

=item *

You should be able to submit a function reference to be called when the various updates (channel info, time, signal, pid) occur.  This is not yet
implemented.

=item *

The power system needs to be revisited.  Currently C<connect> turns the radio off - it should probably preserve state between sessions.

=item *

The channel property isn't being set (correctly anyway).

=item *

Various public properties need to be documented.

=back

Please report any bugs or feature requests to
C<bug-audio-radio-sirius@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Audio-Radio-Sirius>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Mitch and Dale at L<http://rush2112.net> Thanks to everyone who reversed a little bit of the tuner protocol 
- too many to list. :)  You know who you are.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jamie Tatum, all rights reserved.

Sirius and related marks are trademarks of SIRIUS Satellite Radio Inc.  Use of this module is at your own risk and may be subject to the SIRIUS terms and
conditions located at L<http://www.sirius.com/serviceterms>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Audio::Radio::Sirius
