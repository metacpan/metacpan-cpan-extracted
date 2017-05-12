{
package Audio::Nama::Engine;
our $VERSION = 1.0;
use Modern::Perl;
use Carp;
our @ISA;
our %by_name;
our @ports = (57000..57050);
our %port = (
	fof => 57201,
	bus => 57202,
);
use Audio::Nama::Globals qw(:all);
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
				on_reconfigure
    			on_exit
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
sub eval_iam {}
}
{
package Audio::Nama::NetEngine;
our $VERSION = 1.0;
use Modern::Perl;
use Audio::Nama::Log qw(logpkg);
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logit);
use Carp qw(carp);
our @ISA = 'Audio::Nama::Engine';

sub init_ecasound_socket {
	my $self = shift;
	my $port = $self->port;
	Audio::Nama::pager_newline("Creating socket on port $port.");
	$self->{socket} = new IO::Socket::INET (
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
sub eval_iam {
	my $self = shift;
	my $cmd = shift;
	#my $category = Audio::Nama::munge_category(shift());
	my $category = "ECI";

	logit(__LINE__,$category, 'debug', "Net-ECI sent: $cmd");

	$cmd =~ s/\s*$//s; # remove trailing white space
	$this_engine->{socket}->send("$cmd\r\n");
	my $buf;
	# get socket reply, restart ecasound on error
	my $result = $this_engine->{socket}->recv($buf, $config->{engine_command_output_buffer_size});
	defined $result or Audio::Nama::restart_ecasound(), return;

	my ($return_value, $setup_length, $type, $reply) =
		$buf =~ /(\d+)# digits
				 \    # space
				 (\d+)# digits
				 \    # space
 				 ([^\r\n]+) # a line of text, probably one character 
				\r\n    # newline
				(.+)  # rest of string
				/sx;  # s-flag: . matches newline

if(	! $return_value == 256 ){
	logit(__LINE__,$category,'error',"Net-ECI bad return value: $return_value (expected 256)");
	# restart_ecasound(); # TODO

}
	no warnings 'uninitialized';
	$reply =~ s/\s+$//; 

	if( $type eq 'e')
	{
		logit(__LINE__,$category,'error',"ECI error! Command: $cmd. Reply: $reply");
		#restart_ecasound() if $reply =~ /in engine-status/;
	}
	else
	{ 	logit(__LINE__,$category,'debug',"Net-ECI  got: $reply");
		$reply
	}
	
}
} # end package
{
package Audio::Nama::LibEngine;
our $VERSION = 1.0;
use Modern::Perl;
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logit);
our @ISA = 'Audio::Nama::Engine';
sub launch_ecasound_server {
	my $self = shift;
	Audio::Nama::pager_newline("Using Ecasound via Audio::Ecasound (libecasoundc)");
	$self->{ecasound} = Audio::Ecasound->new();
}
sub eval_iam {
	#logsub("&eval_iam");
	my $self = shift;
	my $cmd = shift;
	my $category = Audio::Nama::munge_category(shift());
	
	logit(__LINE__,$category,'debug',"ECI sent: $cmd");

	my (@result) = $this_engine->{ecasound}->eci($cmd);
	logit(__LINE__,$category, 'debug',"ECI  got: @result") 
		if $result[0] and not $cmd =~ /register/ and not $cmd =~ /int-cmd-list/; 
	my $errmsg = $this_engine->{ecasound}->errmsg();
	if( $errmsg ){
		Audio::Nama::restart_ecasound() if $errmsg =~ /in engine-status/;
		$this_engine->{ecasound}->errmsg(''); 
		# Audio::Ecasound already prints error
	}
	"@result";
}
}
1

__END__