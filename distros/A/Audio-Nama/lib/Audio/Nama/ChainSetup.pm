# ---------- ChainSetup-----------

package Audio::Nama::ChainSetup;
use Audio::Nama::Globals qw($file $config $jack $setup %tn %bn %en $mode :trackrw $this_engine);
use Audio::Nama::Log qw(logsub logpkg);
use v5.36;
our $VERSION = 1.0;
use Data::Dumper::Concise;
use Storable qw(dclone);
use Audio::Nama::Util qw(signal_format input_node output_node);
use Audio::Nama::Assign qw(json_out);
no warnings 'uninitialized';

our (

	$g,  # routing graph object - 

		# based on project data 
		# the routing graph is generated,
		# then traversed over, and integrated
		# with track data to generate
		# Audio::Nama::IO objects. Audio::Nama::IO objects are iterated
		# over to generate 
		# the Ecasound chain setup text (c.f. chains command)

	@io, # IO objects corresponding to chain setup

	%is_ecasound_chain, # chains in final chain seutp

	# for sorting final result

	%inputs,
	%outputs,
	%post_input,
	%pre_output,

	# for final result
	
	@input_chains,	# list of input chain segments 
	@output_chains, # list of output chain segments
	@post_input,	# post-input chain operators
	@pre_output, 	# pre-output chain operators

	$chain_setup,	# final result as string
	);


sub remove_temporary_tracks {
	logsub((caller(0))[3]);
	map { logpkg(__FILE__,__LINE__,'debug',"removing temporary track ",$_->group.'/'.$_->name); $_->remove  } 
		grep{ $_->group eq 'Temp' } Audio::Nama::audio_tracks();
}
sub initialize {

	remove_temporary_tracks(); # we will generate them again
	$setup->{audio_length} = 0;  
	@io = (); 			# IO object list
	Audio::Nama::IO::initialize();
	$g = Graph->new(); 	
	%inputs = %outputs = %post_input = %pre_output = ();
	%is_ecasound_chain = ();
	@input_chains = @output_chains = @post_input = @pre_output = ();
	undef $chain_setup;
	Audio::Nama::disable_length_timer();
	reset_aux_chain_counter();
	unlink $file->chain_setup;
	$g;
}
sub ecasound_chain_setup { $chain_setup } 
sub is_ecasound_chain { $is_ecasound_chain{$_[0]} }

sub engine_tracks { Audio::Nama::audio_tracks() } 
sub engine_wav_out_tracks {
	grep{$_->rec} engine_tracks();
}
# return file output entries, including Mixdown 
sub really_recording { 
	my @files = map{ /-o:(.+?\.wav)$/} grep{ /-o:/ and /\.wav$/} split "\n", $chain_setup;
	wantarray() ? @files : scalar @files;
}
	
sub show_io {
	my $output = json_out( \%inputs ). json_out( \%outputs ); 
	Audio::Nama::pager( $output );
}

sub warn_missing_jack_clients {
	for my $track (Audio::Nama::audio_tracks()){
		$track->send_type =~ /jack_client/ and not $jack->{clients}->{$track->send_id}
		 	and Audio::Nama::throw("Track ".$track->name. qq(: JACK client ").$track->send_id.qq(" not found. Skipping aux send));
		$track->source_type eq 'jack_client' and not $jack->{clients}->{$track->source_id}
			and Audio::Nama::throw("Track ".$track->name. qq(: JACK client ").$track->source_id.qq(" not found. Skipping source connection));
	}
}

sub generate_setup_try {
	logsub((caller(0))[3]);

	my $extra_setup_code = shift;

	warn_missing_jack_clients();

	# start with bus routing
	
	map{ $_->apply($g) } Audio::Nama::Bus::all();

	logpkg(__FILE__,__LINE__,'debug',"Graph after bus routing:\n$g");
	
	# now various manual routing

	add_paths_for_aux_sends();
	logpkg(__FILE__,__LINE__,'debug',"Graph after aux sends:\n$g");

	add_paths_from_Main();
	logpkg(__FILE__,__LINE__,'debug',"Graph with paths from Main:\n$g");

	add_paths_for_mixdown_handling();
	logpkg(__FILE__,__LINE__,'debug',"Graph with mixdown mods:\n$g");
	
	$extra_setup_code->($g) if $extra_setup_code;

	prune_graph();
	logpkg(__FILE__,__LINE__,'debug',"Graph after pruning unterminated branches:\n$g");

	Audio::Nama::Graph::expand_graph($g); 

	logpkg(__FILE__,__LINE__,'debug',"Graph after adding loop devices:\n$g");

	Audio::Nama::Graph::add_inserts($g);

	logpkg(__FILE__,__LINE__,'debug',"Graph with inserts:\n$g");

	# Mix tracks to mono if Main is mono
	# (instead of just throwing away right channel)

	if ($g->has_vertex('Main') and $tn{Main}->width == 1)
	{
		$g->set_vertex_attribute('Main', 'ecs_extra' => '-chmix:1')
	}
	#logpkg(__FILE__,__LINE__,'info',sub{"Graph object dump:\n",Dumper($g)});

	# create IO lists %inputs and %outputs

	if ( process_routing_graph() ){
		write_chains(); 
		1
	} else { 
		Audio::Nama::throw("No audio tracks to record or play.");
		0
	}
}

sub add_paths_for_aux_sends { # not including Main

	# currently this routing is track-oriented 

	# we could add this to the Audio::Nama::Bus base class
	# then suppress it in Mixdown and Main groups

	logsub((caller(0))[3]);

	map {  Audio::Nama::Graph::add_path_for_aux_send($g, $_ ) } 
	grep {  $_->group !~ /Mixdown|Null/
			and $_->send_type 
			and $_->rec_status ne OFF } Audio::Nama::audio_tracks();
}


sub add_paths_from_Main {
	logsub((caller(0))[3]);

	if ($mode->mastering){
		$g->add_path(qw[Main Eq Low Boost]);
		$g->add_path(qw[Eq Mid Boost]);
		$g->add_path(qw[Eq High Boost]);
	}
	else { 
		$g->add_path('Main', output_node($tn{Main}->send_type)) if $tn{Main}->mon
			and ! $tn{Mixdown}->rec

		# tests require this, why not generated by
		# add_paths_for_aux_sends() ??
	}

}
sub add_paths_for_mixdown_handling {
	logsub((caller(0))[3]);
	my $final_leg_origin = $mode->mastering ? 'Boost' : 'Main';

	if ($tn{Mixdown}->rw eq REC ){
		# don't monitor via soundcard
		$g->delete_edge('Main','soundcard_out');
		$g->delete_edge('Boost','soundcard_out');
		my @p = ($final_leg_origin, ,'Mixdown', 'wav_out');
		$g->add_path(@p);
		$g->set_vertex_attributes('Mixdown', {
		  	format_template		=> $config->{mix_to_disk_format},
		  	chain_id	=> "Mixdown" },
		); 
		# no effects will be applied because effects are on chain 2
												 
	# Mixdown handling - playback
	
	} elsif ($tn{Mixdown}->rw eq PLAY and $tn{Mixdown}->playback_version()){ 
			my @e = ('wav_in','Mixdown',output_node($tn{Main}->send_type));
			$g->add_path(@e);
			$g->set_vertex_attributes('Mixdown', {
				send_type	=> $tn{Main}->send_type,
				send_id		=> $tn{Main}->send_id,
				chain			=> "Mixdown" }); 
		# no effects will be applied because effects are on chain 2
	}
}
sub prune_graph {
	logsub((caller(0))[3]);
	Audio::Nama::Graph::simplify_send_routing($g);
	logpkg(__FILE__,__LINE__,'debug',"Graph after simplify_send_routing:\n$g");
	Audio::Nama::Graph::remove_out_of_bounds_tracks($g) if Audio::Nama::edit_mode();
	logpkg(__FILE__,__LINE__,'debug',"Graph after remove_out_of_bounds_tracks:\n$g");
	Audio::Nama::Graph::recursively_remove_inputless_tracks($g);
	logpkg(__FILE__,__LINE__,'debug',"Graph after recursively_remove_inputless_tracks:\n$g");
	Audio::Nama::Graph::recursively_remove_outputless_tracks($g); 
	logpkg(__FILE__,__LINE__,'debug',"Graph after recursively_remove_outputless_tracks:\n$g");
}
# object based dispatch from routing graph
	
sub process_routing_graph {
	logsub((caller(0))[3]);

	# generate a set of IO objects from edges
	@io = map{ dispatch($_) } $g->edges;
	
	logpkg(__FILE__,__LINE__,'debug', sub{ join "\n",map $_->dump, @io });

	# sort chain_ids by attached input object
	# one line will show all with that one input
	# -a:3,5,6 -i:foo
	
	map { 
		$inputs{$_->ecs_string} //= [];
		push @{$inputs{$_->ecs_string}}, $_->chain_id;
		$post_input{$_->chain_id} .= $_->ecs_extra if $_->ecs_extra;
		$post_input{$_->chain_id} .= join ' ', map{ $_->ecasound_format } $_->channel_ops if $_->channel_ops 
	} 
	grep { $_->direction eq 'input' } @io;

	map { 
		$outputs{$_->ecs_string} //= [];
		push @{$outputs{$_->ecs_string}}, $_->chain_id;
		$pre_output{$_->chain_id} = $_->ecs_extra if $_->ecs_extra;
	} 
	grep { $_->direction eq 'output' } @io;


	no warnings 'numeric';
	my @in_keys = values %inputs;
	my @out_keys = values %outputs;
	use warnings 'numeric';
	%is_ecasound_chain = map{ $_, 1} map{ @$_ } values %inputs;

	# sort entries into an aesthetic order

	my %rinputs = reverse %inputs;	
	my %routputs = reverse %outputs;	
	@input_chains = sort map {'-a:'.join(',',sort by_chain @$_)." $rinputs{$_}"} @in_keys;
	@output_chains = sort map {'-a:'.join(',',sort by_chain @$_)." $routputs{$_}"} @out_keys;
	@post_input = sort by_index map{ "-a:$_ $post_input{$_}"} keys %post_input;
	@pre_output = sort by_index map{ "-a:$_ $pre_output{$_}"} keys %pre_output;
	@input_chains + @output_chains # to sense empty chain setup
}
{ my ($m,$n,$o,$p,$q,$r);
sub by_chain {
	($m,$n,$o) = $a =~ /(\D*)(\d+)(\D*)/ ;
	($p,$q,$r) = $b =~ /(\D*)(\d+)(\D*)/ ;
	if ($n != $q){ $n <=> $q }
	elsif ( $m ne $p){ $m cmp $p }
	else { $o cmp $r }
}
}
sub by_index {
	my ($i) = $a =~ /(\d+)/;
	my ($j) = $b =~ /(\d+)/;
	$i <=> $j
}

sub non_track_dispatch {

	# loop -> loop
	#	
	# assign chain_id to edge based on chain_id of left-side loop's
	# corresponding track:
	#	
	# hihat_out -- J7a -> Main_in
	#
	# soundcard_in -> wav_out (rec_file)
	#
	# currently handled using an anonymous track
	#
	# we expect edge attributes 
	# to have been provided for handling this. 

	# loop -> soundcard_out
	#
	# track7-soundcard_out as aux_send will have chain id S7
	# that will be transferred by expand_graph() to 
	# the new edge, loop-soundcard-out

	# we will issue two IO objects, one for the chain input
	# fragment, one for the chain output
	
	
	my $edge = shift;
	logpkg(__FILE__,__LINE__,'debug',"non-track IO dispatch:",join ' -> ',@$edge);
	my $eattr = $g->get_edge_attributes(@$edge) // {};
	logpkg(__FILE__,__LINE__,'debug',"found edge attributes: ",json_out($eattr)) if $eattr;

	my $vattr = $g->get_vertex_attributes($edge->[0]) // {};
	logpkg(__FILE__,__LINE__,'debug',"found vertex attributes: ",json_out($vattr)) if $vattr;

	if ( ! $eattr->{chain_id} and ! $vattr->{chain_id} ){
		my $n = $eattr->{n} || $vattr->{n};
		$eattr->{chain_id} = jumper_count($n);
	}
	my @direction = qw(input output);
	map{ 
		my $direction = shift @direction;
		my $class = Audio::Nama::IO::get_class($_, $direction);
		my $attrib = {%$vattr, %$eattr};
		$attrib->{endpoint} //= $_ if Audio::Nama::Graph::is_a_loop($_); 
		logpkg(__FILE__,__LINE__,'debug',"non-track: $_, class: $class, chain_id: $attrib->{chain_id},","device_id: $attrib->{device_id}");
		my $io = $class->new($attrib ? %$attrib : () ) ;
		$g->set_edge_attribute(@$edge, $direction, $io);
		$io;
	} @$edge;
}

{ 
### counter for jumper chains 
#
#   sequence: J1 J1a J1b J1c, J2, J3, J4, J4d, J4e

my %used;
my $counter;
my $prefix = 'J';
reset_aux_chain_counter();
  
sub reset_aux_chain_counter {
	%used = ();
	$counter = 'a';
}
sub jumper_count {
	my $track_index = shift;
	my $try1 = $prefix . $track_index;
	$used{$try1}++, return $try1 unless $used{$try1};
	$try1 . $counter++;
}
}
sub dispatch { # creates an IO object from a graph edge
	my $edge = shift;
	return non_track_dispatch($edge) if not grep{ $tn{$_} } @$edge ;
	logpkg(__FILE__,__LINE__,'debug','dispatch: ',join ' -> ',  @$edge);
	my($name, $endpoint, $direction) = decode_edge($edge);
	logpkg(__FILE__,__LINE__,'debug',"name: $name, endpoint: $endpoint, direction: $direction");
	my $track = $tn{$name};
	my $class = Audio::Nama::IO::get_class( $endpoint, $direction );
		# we need the $direction because there can be 
		# edges to and from loop,Main_in
		
	my @args = (track => $name,
				endpoint => massaged_endpoint($track, $endpoint, $direction),
				chain_id => $tn{$name}->n, # default
				override($name, $edge));   # priority: edge > node
	#say "dispatch class: $class";
	my $io = $class->new(@args);

	$g->set_edge_attribute(@$edge, $direction => $io );
	$io
}
sub massaged_endpoint {
	my ($track, $endpoint, $direction) = @_;
	if ( $endpoint =~ /^(loop_in|loop_out)$/ ){
		my $final = ($direction eq 'input' ?  $track->source_id : $track->send_id );
		$final =~ s/^loop,//;
		$final		
	} else { $endpoint }
}
sub decode_edge {
	# assume track-endpoint or endpoint-track
	# return track, endpoint
	my ($a, $b) = @{$_[0]};
	#say "a: $a, b: $b";
	my ($name, $endpoint) = $tn{$a} ? @{$_[0]} : reverse @{$_[0]} ;
	my $direction = $tn{$a} ? 'output' : 'input';
	($name, $endpoint, $direction)
}
sub override {
	# data from edges has priority over data from vertexes
	# we specify $name, because it could be left or right 
	# vertex
	logsub((caller(0))[3]);
	my ($name, $edge) = @_;
	(override_from_vertex($name), override_from_edge($edge))
}
	
sub override_from_vertex {
	my $name = shift;
		warn("undefined graph\n"), return () unless (ref $g) =~ /Graph/;
		my $attr = $g->get_vertex_attributes($name);
		$attr ? %$attr : ();
}
sub override_from_edge {
	my $edge = shift;
		warn("undefined graph\n"), return () unless (ref $g) =~ /Graph/;
		my $attr = $g->get_edge_attributes(@$edge);
		$attr ? %$attr : ();
}
							
sub write_chains {

	logsub((caller(0))[3]);

	## write general options
	
	my @globals;
	my $format = signal_format($config->{devices}->{jack}->{signal_format},2); # HARDCODED XXX
	push @globals, $config->{ecasound_globals}->{common};
	push @globals, "-f:$format", join(',', 	'-G:jack',
										$config->{ecasound_jack_client_name},
										$config->{jack_transport_mode}
							) if $jack->{jackd_running};

	push @globals, "-b", $config->buffersize, $config->globals_realtime;
	my $globals = join " ", @globals;
	
	my $ecs_file = join "\n\n", 
					"# ecasound chainsetup file",
					"# general",
					$globals, 
					"# audio inputs",
					join("\n", @input_chains), "";
	$ecs_file .= join "\n\n", 
					"# post-input processing",
					join("\n", @post_input), "" if @post_input;				
	$ecs_file .= join "\n\n", 
					"# pre-output processing",
					join("\n", @pre_output), "" if @pre_output;
	$ecs_file .= join "\n\n", 
					"# audio outputs",
					join("\n", @output_chains), "";
	logpkg(__FILE__,__LINE__,'debug',"Chain setup:\n",$ecs_file);
	open(my $fh, ">", $file->chain_setup) 
		or die("can't open chain setup file ".$file->chain_setup.": $!");
	print $fh $ecs_file;
	close $fh;
	$chain_setup = $ecs_file;

}
sub setup_requires_realtime {
	my $prof = $config->{realtime_profile};
	if( $prof eq 'auto'){
		grep{ ! $_->is_mixing 
				  and $_->is_user_track 
				  and ($_->rec or $_->mon)
			} Audio::Nama::audio_tracks() 
	} elsif ( $prof eq 'realtime') {
		my @fields = qw(soundcard jack_client jack_manual jack_ports_list);
		grep { has_vertex("$_\_in") } @fields 
			or grep { has_vertex("$_\_out") } @fields
	}
	elsif ( $prof eq 'nonrealtime' or !$prof){}
}

sub has_vertex { $g->has_vertex($_[0]) }

1;
__END__

=head1 NAME

=encoding UTF-8

Audio::Nama::ChainSetup - routines for generating Ecasound chain setup

=head2 Overview

For the Ecasound engine to run, it must be configured into a
signal processing network. This configuration is called a
"chain setup".  It is a graph comprised of multiple signal
processing chains, each of which consists of exactly one
input and one output.

When user input requires a change of configuration, Nama
generates an new chain setup file. These files are
guaranteed to be consistent with the rules of Ecasound's
routing language. 

After initializing the data structures, Nama iterates over
project tracks and buses to create a first-stage graph.
This graph is successively transformed as more routing
details are added, then each edge of the graph is processed
into a pair of IO objects--one for input and one for
output--that together constitute an Ecasound chain. With a
bit more processing, the configuration is written out 
as text in the chain setup file.

=head2 The Graph and its Transformations

Generating a chain setup starts with each bus iterating over
its member tracks, and connecting them to its mix track.
(See man Audio::Nama::Bus.)

In the case of one track belonging to the Main (default) 
bus, the initial graph would be:

	soundcard_in -> sax -> Main -> soundcard_out

"soundcard_in" and "soundcard_out" will eventually be mapped
to the appropriate JACK or ALSA source, depending on whether
jackd is running. The Main track hosts the master fader,
connects to the main output, and serves as the mix track for
the Main bus.

If we've asked to record the input, we automatically get
this route:

	soundcard_in -> sax-rec-file -> wav_out

The track 'sax-rec-file' is a temporary clone (slave) of track 'sax'
and connects to all the same inputs.

A 'send' (for example, a instrument monitor for
the sax player) generates this additional route:

	sax -> soundcard_out

Ecasound requires that we insert a loop device where signals fan 
out or fan in.

	soundcard_in -> sax -> sax_out -> Main -> soundcard_out

	                       sax_out -> soundcard_out

Here 'sax_out' is a loop device. (Note that we prohibit
track names matching *_out or *_in.)

Inserts are incorporated by replacing the edge either before
or after a track vertex with a network of auxiliary tracks and 
loop devices.  (See man Audio::Nama::Insert.)

Unterminated parts of the network are discarded. Then
redundant loop devices are removed from the graph to
minimize latency.

=head2 Dispatch

After routing is complete, Nama iterates over the graph's
edges, transforming them into pairs of IO objects that
become the inputs and outputs of Ecasound chains.

To create an Ecasound chain from 

	Main -> soundcard_out 

Nama uses 'Main' track attributes to provide
data. For example track index (1) serves as the chain_id,
and the track's send settings determine the soundcard
channel or other destination. 

Some edges are without a track at either terminal. For
example this auxiliary send:

	sax_out -> soundcard_out

In this case, the track, chain_id and other data can be
specified as vertex or edge attributes. 

Edge attributes override vertex attributes, which override
track attributes. This allows routing to be edited and
annotated to behaviors different from what the track wants.
When a temporary track is used for recording, for example

    sax-rec-file  -> wav_out

The 'sax-rec-file' vertex is assigned the 'chain_id' attribute 
'R3' rather than the track index assigned to 'sax-rec-file'. 