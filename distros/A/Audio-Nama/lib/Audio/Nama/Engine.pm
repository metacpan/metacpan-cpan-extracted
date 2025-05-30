{
package Audio::Nama::Engine;
our $VERSION = 1.0;
use v5.36;
use Carp;
our @ISA;
our %by_name;
our @ports = (57000..57050);
our %port = (
	fof => 57201,
	bus => 57202,
);
use Audio::Nama::Globals qw(:all);
use Role::Tiny::With;
with 'Audio::Nama::EcasoundSetup';
use Audio::Nama::Object qw( 
name 
port 
jack_seek_delay 
jack_transport_mode
events
socket
pids
ecasound
buffersize
ready

				 );

sub new {
	my $class = shift;	
	my %vals = @_;
	croak "undeclared field: @_" if grep{ ! $_is_field{$_} } keys %vals;
	Audio::Nama::pager_newline("$vals{name}: returning existing engine"), 
		return $by_name{$vals{name}} if $by_name{$vals{name}};
	my $self = bless { name => 'default', %vals }, $class;
	#print "object class: $class, object type: ", ref $self, $/;
	$by_name{ $self->name } = $self;
	$self->initialize_ecasound();
	$this_engine = $self;
}
sub initialize_ecasound { 
	my $self = shift;
 	my @existing_pids = split " ", qx(pgrep ecasound);
	$self->launch_ecasound_server;
	$self->{pids} = [ 
		grep{ 	my $pid = $_; ! grep{ $pid == $_ } @existing_pids }	
		split " ", qx(pgrep ecasound) 
	];
}
sub launch_ecasound_server {}

sub kill_and_reap {
		my $self = shift;
		Audio::Nama::kill_and_reap( @{$self->{pids}} );
}
sub tracks {
	my $self = shift;
	my @tracks = grep { $self->name eq $_->engine_group } Audio::Nama::all_tracks();
}
sub ecasound_iam {}

# the purpose of the following methods is to cache results
# from the engine, so we don't burden it with extra
# commands while the engine is running.

#sub started { $_[0]->{started} } # cached
sub started { $_[0]->running } # not cached
sub stopped { ! $_[0]->started } # cached
sub running { no warnings 'uninitialized'; $_[0]->ecasound_iam("engine-status") eq 'running' }

sub current_item {
	my ($self, $n, $field, $cmd, $reset_sub) = @_;
	no warnings 'uninitialized';
	logpkg(__FILE__,__LINE__,'debug',"field: $field, n: $n, was: $self->{field} cmd: $cmd, reset sub: ", $reset_sub ? "yes" : "no");

	# caching behavior: 

	# do not execute if newly assigned value same as stored value

	return $self->{$field} if ! $n or $n > 0 and $self->{$field} == $n;

	# otherwise execute command and cache new value

	$self->ecasound_iam("$cmd $n");
	&$reset_sub if $reset_sub;
	$self->{$field} = $n;
}
sub current_chain {
	my ($self, $n) = @_;
	$self->current_item($n, 'current_chain', 'c-select', \&reset_ecasound_selections_cache);
}
sub reset_ecasound_selections_cache {
	my $self = shift;
	delete $self->{$_} for qw(	current_chain
								current_chain_operator
								current_chain_operator_parameter
								current_controller 
								current_controller_parameter);

}
sub reset_current_controller {
	my $self = shift;
	delete $self->{$_} for qw(current_controller current_controller_parameter)  
}
sub current_chain_operator {
	my ($self, $n) = @_;
	$self->current_item($n, 'current_chain_operator', 'cop-select', \&reset_ecasound_selections_cache)
}
sub current_chain_operator_parameter {
	my ($self, $n) = @_;
	$self->current_item($n, 'current_chain_operator_parameter', 'copp-select', \&reset_current_controller);
}
sub current_controller {
	my ($self, $n) = @_;
	$self->current_item($n, 'current_controller', 'ctrl-select', \&reset_current_controller);
}
sub current_controller_parameter {
	my ($self, $n) = @_;
	$self->current_item($n, 'current_controller_parameter', 'ctrlp-select');
}
sub valid_setup {
	my ($self) = @_;
	$self->ecasound_iam('cs-selected') and 
	$self->ecasound_iam('cs-is-valid');
}

### class methods

sub engines { values %by_name }

sub sync_action {
	my ($method, @args) = @_;
	$_->$method(@args) for engines()
}
}

{
package Audio::Nama::NetEngine;
our $VERSION = 1.0;
use v5.36;
use Audio::Nama::Log qw(logpkg logit);
use Audio::Nama::Globals qw(:all);
use Carp qw(carp);
use Role::Tiny::With;
with 'Audio::Nama::EcasoundRun';
with 'Audio::Nama::EcasoundCleanup';

our @ISA = 'Audio::Nama::Engine';

sub init_ecasound_socket {
	my $self = shift;
	my $port = $self->port;
	Audio::Nama::pager_newline("Creating socket on port $port.");
	$self->{socket} = IO::Socket::INET->new (
		PeerAddr => 'localhost', 
		PeerPort => $port, 
		Proto => 'tcp', 
	); 
	die "Could not create socket: $!\n" unless $self->{socket}; 
}
sub launch_ecasound_server {
	my $self = shift;
	my $port = $self->port;
	
	# we'll try to communicate with an existing ecasound
	# process provided:
	#
	# started with --server option
	# --server-tcp-port option matches 
	
	my $command = "ecasound -K -C --server --server-tcp-port=$port";
	my $redirect = ">/dev/null &";
	my $ps = qx(ps ax);
	if ( $ps =~ /ecasound/ and $ps =~ /--server/ and ($ps =~ /tcp-port=$port/) )
	{ 
		Audio::Nama::pager_newline("Found existing Ecasound server on port $port") 
	}
	else 
	{ 
		
		Audio::Nama::pager_newline("Starting Ecasound server on port $port");
		system("$command $redirect") == 0 or carp("system $command failed: $?\n")
	}
	sleep 1;
	$self->init_ecasound_socket();
}
sub ecasound_iam{
	my $self = shift;
	my $cmd = shift;
	#my $category = Audio::Nama::munge_category(shift());
	my $category = "ECI";

	logit(__LINE__,$category, 'debug', "Net-ECI sent: $cmd");

	$cmd =~ s/\s*$//s; # remove trailing white space
	$en{$Audio::Nama::config->{ecasound_engine_name}}->{socket}->send("$cmd\r\n");
	my $buf;
	# get socket reply, restart ecasound on error
	my $result = $en{$Audio::Nama::config->{ecasound_engine_name}}->{socket}->recv($buf, $config->{engine_command_output_buffer_size});
	defined $result or Audio::Nama::throw("Ecasound failed to respond"), return;

	my ($return_value, $setup_length, $type, $reply) =
		$buf =~ /(\d+)# digits, log_level
				 \    # space
				 (\d+)# digits, msg_size
				 \    # space
 				 ([^\r\n]+) # string, return_type 
				\r\n    # newline
				(.+)  # rest of string, message
				/sx;  # s-flag: . matches newline

if(	! $return_value == 256 ){
	logit(__LINE__,$category,'error',"Net-ECI bad return value: $return_value (expected 256)");

}
	no warnings 'uninitialized';
	$reply =~ s/\s+$//; 

	if( $type eq 'e')
	{
		logit(__LINE__,$category,'error',"ECI error! Command: $cmd. Reply: $reply");
	}
	else
	{ 	logit(__LINE__,$category,'debug',"Net-ECI  got: $reply");
		$reply
	}
	
}
sub configure {
	package Audio::Nama;
	my $self = shift;
	my $force = shift;

	# don't disturb recording/mixing
	
	return if Audio::Nama::ChainSetup::really_recording() and $this_engine->running();
	
	# store a lists of wav-recording tracks for the rerecord
	# function
	
	if( $setup->{changed} ){ 
		logpkg(__FILE__,__LINE__,'debug',"reconfigure requested");
		$setup->{_old_snapshot} = status_snapshot_string();
} 
	else {
		my $old = $setup->{_old_snapshot};
		my $current = $setup->{_old_snapshot} = status_snapshot_string();	
		if ( $current eq $old){
				logpkg(__FILE__,__LINE__,'debug',"no change in setup");
				return;
		}
		logpkg(__FILE__,__LINE__,'debug',"detected configuration change");
		logpkg(__FILE__,__LINE__,'debug', diff(\$old, \$current));
	}
	$setup->{changed} = 0 ; # reset for next time

	nama_cmd('show_tracks');

	{ local $quiet = 1; stop_transport() }

	trigger_rec_cleanup_hooks();
	trigger_rec_setup_hooks();
	$setup->{_old_rec_status} = { 
		map{$_->name => $_->rec_status } rec_hookable_tracks()
	};
	if ( $self->setup() ){

		reset_latency_compensation() if $config->{opts}->{Q};
		
		logpkg(__FILE__,__LINE__,'debug',"I generated a new setup");
		
		{ local $quiet = 1; connect_transport() }
		propagate_latency() if $config->{opts}->{Q} and $jack->{jackd_running};
		show_status();

		if ( Audio::Nama::ChainSetup::really_recording() )
		{
			$project->{playback_position} = 0
		}
		else 
		{ 
			set_position($project->{playback_position}) if $project->{playback_position} 
		}
		$self->start_transport('quiet') if $mode->eager 
								and ($mode->doodle or $mode->preview);
		transport_status();
		$ui->flash_ready;
		1
	}
}
} # end package
{
package Audio::Nama::LibEngine;
our $VERSION = 1.0;
use v5.36;
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logit);
our @ISA = 'Audio::Nama::Engine';
use Role::Tiny::With;
with 'Audio::Nama::EcasoundRun';

sub launch_ecasound_server {
	my $self = shift;
	Audio::Nama::pager_newline("Using Ecasound via Audio::Ecasound (libecasoundc)");
	$self->{audio_ecasound} = Audio::Ecasound->new();
}
sub ecasound_iam{
	#logsub((caller(0))[3]);
	my $self = shift;
	my $cmd = shift;
	my $category = Audio::Nama::munge_category(shift());
	
	logit(__LINE__,$category,'debug',"LibEcasound-ECI sent: $cmd");

	my (@result) = $self->{audio_ecasound}->eci($cmd);
	logit(__LINE__,$category, 'debug',"LibEcasound-ECI  got: @result") 
		if $result[0] and not $cmd =~ /register/ and not $cmd =~ /int-cmd-list/; 
	my $errmsg = $self->{audio_ecasound}->errmsg();
	if( $errmsg ){
		Audio::Nama::throw("Ecasound error: $errmsg") if $errmsg =~ /in engine-status/;
		$self->{audio_ecasound}->errmsg(''); 
	}
	"@result";
}
sub configure { Audio::Nama::NetEngine::configure(@_) }
} # end package
{ 
package Audio::Nama::MidiEngine;
use v5.36;
use SUPER;
use Audio::Nama::Globals qw($config %tn);
our $VERSION = 1.0;
our @ISA = 'Audio::Nama::Engine';

sub new {
	my $self = super(); 
	$self->{pids} = [ Audio::Nama::start_midish_process() ];
	$self
}
sub configure { }
sub setup { Audio::Nama::reconfigure_midi() }
sub stop { Audio::Nama::stop_midi_transport() }
sub cleanup { Audio::Nama::midi_rec_cleanup() }
sub start { Audio::Nama::start_midi_transport() }
sub rec_tracks { grep {$_->rec} $_[0]->user_tracks }
sub system_tracks { $tn{$config->{midi_record_buffer}}}
sub user_tracks { grep { $_->name ne $config->{midi_record_buffer} } $_[0]->tracks }
sub play_tracks { grep {$_->play} $_[0]->user_tracks }
sub is_active { $_[0]->rec_tracks or $_[0]->play_tracks }
		
} # end package 
1

__END__