package Audio::Nama::Graph;
use v5.36;
our $VERSION = 1.0;
use Carp;
use Graph;
use Audio::Nama::Util qw(input_node output_node);
use Audio::Nama::Log qw(logsub logpkg);
use Audio::Nama::Globals qw(:trackrw);
our(%reserved);
# this dispatch table also identifies labels reserved
# for signal sources and sinks.
*reserved = \%Audio::Nama::IO::io_class;

sub add_path_for_rec {

	# connect input source to file 
	
	my($g,$track) = @_;

	logsub("&add_path_for_rec: track ".$track->name);

	# Case 1: Regular track
	if( $track->source_type !~ /track|bus|loop/  and !  $track->is_mixing)
	{
		# create temporary track for rec_file chain

		# (it may be possible to avoid creating a 
		# temporary track by providing the data as 
		# graph edge attributes)

		logpkg(__FILE__,__LINE__,'debug',"rec file link for ".$track->name);
		my $name = $track->name . '_rec_file';
		my $anon = Audio::Nama::SlaveTrack->new( 
			target => $track->name,
			rw => OFF,
			group => 'Temp',
			hide => 1,
			novol => 1,
			nopan => 1,
			name => $name);

		# connect writepath: source --> temptrackname --> wav_out
		
		$g->add_path(input_node($track->source_type), $name, 'wav_out');


		$g->set_vertex_attributes($name, { 

			# set chain_id to R3 (if original track is 3) 

			chain_id => 'R'.$track->n,

			# do not perform mono-to-stereo copy,
			# (override IO class default)

			mono_to_stereo => '', 
		});

	} 
	# Case 2: Mix track
	elsif ($track->source_type =~ /bus|track/ or $track->is_mixing) 
	{

		my $name = $track->name . '_rec_file';
		my $anon = Audio::Nama::SlaveTrack->new( 
			target => $track->name,
			rw => OFF,
			group => 'Temp',
			hide => 1,
			novol => 1,
			nopan => 1,
			name => $name);

		my @edge = ($track->name, 'wav_out');

		$g->add_path(@edge); 

		# set chain_id same as original track

		$g->set_edge_attributes(@edge, { 
			chain_id => $track->n,
		});
		
	}
}
sub add_path_for_aux_send {
	my ($g, $track) = @_;
	add_path_for_send($g, map{ $track->$_ } qw(name send_type send_id) );
}
sub add_path_for_send {
	my ($g, $name, $send_type, $send_id)  = @_;

	logsub("&add_path_for_aux_send: track ".$name);
	logpkg(__FILE__,__LINE__,'debug',"args: graph: $g, name: $name, send_type, $send_type, send_id: $send_id");

	# for track 'sax', send_type 'track' send_id 'vocal'
	#
	my @path;

	if ( $send_type eq 'track'){
		@path = ($name, $send_id)
	}
	else {
		
		# for track 'sax', send_type 'jack_client', create route as 
		# sax -> sax_aux_send -> jack_client_out
		
		my $nameof = $name . '_aux_send';
		my $anon = Audio::Nama::SlaveTrack->new( 
			target => $name,
			rw => OFF,
			group => 'Temp',
			hide => 1,
			name => $nameof);

		@path= ($name, $nameof, output_node($send_type));
	}
	logpkg(__FILE__,__LINE__,'debug',"adding path ", join '-',@path);
	$g->add_path(@path);
}
{
my %seen;

sub expand_graph {
	
	my $g = shift; 
	%seen = ();
	
	
	for ($g->edges){
		my($a,$b) = @{$_}; 
		logpkg(__FILE__,__LINE__,'debug',"$a-$b: processing...");
		logpkg(__FILE__,__LINE__,'debug',"$a-$b: already seen") if $seen{"$a-$b"};
		next if $seen{"$a-$b"};

		# case 1: both nodes are tracks: default insertion logic
	
		if ( is_a_track($a) and is_a_track($b) ){ 
			logpkg(__FILE__,__LINE__,'debug',"processing track-track edge: $a-$b");
			add_loop($g,$a,$b) } 

		# case 2: fan out from track: use near side loop

		elsif ( is_a_track($a) and $g->successors($a) > 1 ) {
			logpkg(__FILE__,__LINE__,'debug',"fan_out from track $a");
			add_near_side_loop($g,$a,$b,out_loop($a));}
	
		# case 3: fan in to track: use far side loop
		
		elsif ( is_a_track($b) and $g->predecessors($b) > 1 ) {
			logpkg(__FILE__,__LINE__,'debug',"fan in to track $b");
			add_far_side_loop($g,$a,$b,in_loop($b));}
		else { logpkg(__FILE__,__LINE__,'debug',"$a-$b: no action taken") }
	}
	
}
	
sub add_inserts {
	my $g = shift;
	map{ my $i = $Audio::Nama::tn{$_}->prefader_insert;
		 $Audio::Nama::Insert::by_index{$i}->add_paths($g, $_) if $i;
			$i = $Audio::Nama::tn{$_}->postfader_insert;
		 $Audio::Nama::Insert::by_index{$i}->add_paths($g, $_) if $i;
	}
	grep{ $Audio::Nama::tn{$_} } 
	$g->vertices;
}

sub add_loop {
	my ($g,$a,$b) = @_;
	logpkg(__FILE__,__LINE__,'debug',"adding loop");
	my $fan_out = $g->successors($a);
	logpkg(__FILE__,__LINE__,'debug',"$a: fan_out $fan_out");
	my $fan_in  = $g->predecessors($b);
	logpkg(__FILE__,__LINE__,'debug',"$b: fan_in $fan_in");
	if ($fan_out > 1){
		add_near_side_loop($g,$a,$b, out_loop($a))
	} elsif ($fan_in  > 1){
		add_far_side_loop($g,$a,$b, in_loop($b))
	} elsif ($fan_in == 1 and $fan_out == 1){

	# we expect a single user track to feed to Main_in 
	# as multiple user tracks do
	
			$b eq 'Main' 
				?  add_far_side_loop($g,$a,$b,in_loop($b))

	# otherwise default to near_side ( *_out ) loops
				: add_near_side_loop($g,$a,$b,out_loop($a));

	} else {croak "unexpected fan"};
}

 sub add_near_side_loop {

# a - b
# a - c
# a - d
#
# converts to 
#
# a_out - b
# a_out - c
# a_out - d
# a - a_out

# we deal with all edges departing from $a, the left node.
# I call it a-x below, but it is actually a-$_ where $_ 
# is an alias to each of the successor node.
#
# 1. start with a - x
# 
# 2. delete a - x 
# 
# 3. add a - a_out
# 
# 4. add a_out - x
# 
# 5. Add a_out attributes for track name and 
#    other info need to generate correct chain_ids
#
# 6. Copy any attributes of edge a - x  to a_out - x.
#
#  No multiedge handling needed because with our 
#  current topology, we never have a track
#  with, for example, multiple edges to a soundcard.
#
#  Send buses create new tracks to provide connections.

 	my ($g, $a, $b, $loop) = @_;
 	logpkg(__FILE__,__LINE__,'debug',"$a-$b: insert near side loop");
	# we will insert loop _after_ processing successor
	# edges so $a-$loop will not be picked up 
	# in successors list.
	
	# We will assign chain_ids to loop-to-loop edges
	# looking like J7a, J7b,...
	#
	# To make this possible, we store the following 
	# information in the left vertex of
	# the edge:
	#
	# n: track index, j: alphabetical counter
	 
	$g->set_vertex_attributes($loop,{
		n => $Audio::Nama::tn{$a}->n, j => 'a',
		track => $Audio::Nama::tn{$a}->name});
	map{ 
 		my $attr = $g->get_edge_attributes($a,$_);
 		logpkg(__FILE__,__LINE__,'debug',"deleting edge: $a-$_");
 		$g->delete_edge($a,$_);
		$g->add_edge($loop, $_);
		$g->set_edge_attributes($loop,$_, $attr) if $attr;
		$seen{"$a-$_"}++;
 	} $g->successors($a);
	$g->add_edge($a,$loop);
}
 

sub add_far_side_loop {
 	my ($g, $a, $b, $loop) = @_;
 	logpkg(__FILE__,__LINE__,'debug',"$a-$b: insert far side loop");
	
	$g->set_vertex_attributes($loop,{
		n => $Audio::Nama::tn{$a}->n, j => 'a',
		track => $Audio::Nama::tn{$a}->name});
	map{ 
 		my $attr = $g->get_edge_attributes($_,$b);
 		logpkg(__FILE__,__LINE__,'debug',"deleting edge: $_-$b");
 		$g->delete_edge($_,$b);
		$g->add_edge($_,$loop);
		$g->set_edge_attributes($_,$loop, $attr) if $attr;
		$seen{"$_-$b"}++;
 	} $g->predecessors($b);
	$g->add_edge($loop,$b);
}

}

sub in_loop{ "$_[0]_in" }
sub out_loop{ "$_[0]_out" }
sub is_a_track{ $Audio::Nama::tn{$_[0]} }  # most reliable
sub is_terminal { $reserved{$_[0]} or is_port($_[0]) }
sub is_port { $_[0] =~ /^[^:]+:[^:]+$/ }
sub is_a_loop{
	my $name = shift;
	return if $reserved{$name};
	if (my($root, $suffix) = $name =~ /^(.+?)_(in|out|insert_p.+)$/){
		return ($root, $suffix);
	} 
}
sub inputless_tracks {
	my $g = shift;
	(grep{ is_a_track($_) and $g->is_source_vertex($_) } $g->vertices)
}	
sub remove_out_of_bounds_tracks {
	my $g = shift;
	my @names = $g->successors('wav_in');  # PLAY status tracks
	map{ remove_tracks($g, $_) } 
	grep{
		Audio::Nama::edit_case(Audio::Nama::edit_vars($Audio::Nama::tn{$_})) =~ /out_of_bounds/
	} @names;
}

sub recursively_remove_inputless_tracks {
	my $g = shift;
	# make multiple passes if necessary
	while(my @i = inputless_tracks($g)){
		remove_tracks($g, @i);
	}
}
sub outputless_tracks {
	my $g = shift;
	(grep{ is_a_track($_) and $g->is_sink_vertex($_) } $g->vertices)
}	
sub recursively_remove_outputless_tracks {
	my $g = shift;
	while(my @i = outputless_tracks($g)){
		remove_tracks($g, @i);
	}
}
sub remove_tracks {
	my ($g, @names) = @_;
		map{ 	$g->delete_edges(map{@$_} $g->edges_from($_));
				$g->delete_edges(map{@$_} $g->edges_to($_));
				$g->delete_vertex($_);
		} @names;
}

sub remove_branch {
	my ($g, $v) = @_;
	my @p = $g->predecessors($v);
	$g->delete_vertex($v) if $g->is_sink_vertex($v);
	remove_branch($g, $_) for @p;
}

sub remove_isolated_vertices {
	my $g = shift;
	map{ $g->delete_vertex($_) } 
	grep{ $g->is_isolated_vertex($_) } $g->vertices();	
}

sub simplify_send_routing {
	my $g = shift;
	for( grep { is_a_track($_) } $g->vertices ){
		my $aux = "$_\_aux_send";
		my @successors;
		if( $g->has_edge($_, $aux)
			and @successors = $g->successors($_)
			and scalar @successors == 1
		){
			my ($output) = $g->successors($aux);
			$g->delete_path($_, $aux, $output);
			$g->add_edge($_, $output);
		}	
	}
}

1;
__END__