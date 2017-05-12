package Audio::Nama::Sequence;
use Modern::Perl; use Carp; 
use Audio::Nama::Assign qw(json_out);
use Audio::Nama::Log qw(logsub logpkg);
use Audio::Nama::Effect  qw(fxn modify_effect);
use Audio::Nama::Object qw( items clip_counter );
use Audio::Nama::Globals qw(:trackrw);
our @ISA = 'Audio::Nama::SubBus';
our $VERSION = 1.0;
use SUPER;
our %by_name; # alias to %Audio::Nama::Bus::by_name
*by_name = \%Audio::Nama::Bus::by_name; 

sub new { 
	my ($class,%args) = @_;
	# take out args we will process
	my $items = delete $args{items};
	my $counter = delete $args{clip_counter};
	#logpkg(__FILE__,__LINE__,'debug', "items: ",map{json_out($_->as_hash)}map{$Audio::Nama::tn{$_}}@$items) if $items;
	$items //= [];
	@_ = ($class, %args);
	my $self = super();
	logpkg(__FILE__,__LINE__,'debug',"new object: ", json_out($self->as_hash));
	logpkg(__FILE__,__LINE__,'debug', "items: ",json_out($items));
	$self->{clip_counter} = $counter;
	$self->{items} = $items;
	$Audio::Nama::this_sequence = $self;
	$self;
} 
sub clip {
	my ($self, $index) = @_;
	return 0 if $index <= 0;
	$Audio::Nama::tn{$self->{items}->[$index - 1]}
}
sub rw { 
	my $self = shift;
	$Audio::Nama::mode->{offset_run} ? OFF : $self->{rw}
}
# perl indexes arrays at zero, for nama users we number items from one
sub insert_item {
	my $self = shift;
	my ($item, $index) = @_;
	$self->append_item($item), return if $index == @{$self->{items}} + 1;
	$self->verify_item($index) or die "$index: sequence index out of range";
	splice @{$self->{items}}, $index - 1,0, $item->name 
}
sub verify_item {
	my ($self, $index) = @_;
	$index >= 1 and $index <= scalar @{$self->items} 
}
sub delete_item {
	my $self = shift;
	my $index = shift;
	$self->verify_item($index) or die "$index: sequence index out of range";
	my $trackname = splice(@{$self->{items}}, $index - 1, 1);
	$Audio::Nama::tn{$trackname} and $Audio::Nama::tn{$trackname}->remove;
}
sub append_item {
	my $self = shift;
	my $item = shift;
	push( @{$self->{items}}, $item->name );
}
sub item {
	my $self = shift;
	my $index = shift;
	return 0 if $index <= 0;
	$Audio::Nama::tn{$self->{items}->[$index - 1]};
}
sub list_output {
	my $self = shift;
	my $i;
	join "\n","Sequence $self->{name} clips:",
		map { join " ", 
				++$i, 
				$Audio::Nama::tn{$_}->n,
				$_,
				sprintf("%.3f %.3f", $Audio::Nama::tn{$_}->duration, $Audio::Nama::tn{$_}->endpoint),
		} @{$self->items}
}
sub remove {
	my $sequence = shift;

	# delete all clips
	map{$Audio::Nama::tn{$_}->remove } $by_name{$sequence->name}->tracks;

	# delete clip array
	delete $sequence->{items};
	
	my $mix_track = $Audio::Nama::tn{$sequence->name};

	if ( defined $mix_track ){
	 
		$mix_track->unbusify;
	
		# remove mix track unless it has some WAV files

		$mix_track->remove unless scalar @{ $mix_track->versions };
	}

	# remove sequence from index
	
	delete $by_name{$sequence->name};
} 
sub new_clip {
	my ($self, $track, %args) = @_; # $track can be object or name
	my $markpair = delete $args{region};
	logpkg(__FILE__,__LINE__,'debug',json_out($self->as_hash), json_out($track->as_hash));
	ref $track or $track = $Audio::Nama::tn{$track} 
		or die("$track: track not found."); 
	my %region_args = (
		region_start => $markpair && $markpair->[0]->name || $track->region_start,
		region_end	 => $markpair && $markpair->[1]->name || $track->region_end
	);
	my $clip = Audio::Nama::Clip->new(
		target => $track->basename,
		name => $self->unique_clip_name($track->name, $track->monitor_version),
		rw => PLAY,
		group => $self->name,
		version => $track->monitor_version,
		hide => 1,
		%region_args,
		%args
	);
	modify_effect( $clip->vol, 1, undef, fxn($track->vol)->params->[0]);
	modify_effect( $clip->pan, 1, undef, fxn($track->pan)->params->[0]);
	$clip
}
sub new_spacer {
	my( $self, %args ) = @_;
	my $position = delete $args{position};
	my $spacer = Audio::Nama::Spacer->new( 
		duration => $args{duration},
		name => $self->unique_spacer_name(),
		rw => OFF,
		group => $self->name,
	);
	$self->insert_item( $spacer, $position || ( scalar @{ $self->{items} } + 1 ))
}
sub unique_clip_name {
	my ($self, $trackname, $version) = @_;
	join '-', $self->name , ++$self->{clip_counter}, $trackname, 'v'.$version;
}
sub unique_spacer_name {
	my $self = shift;
	join '-', $self->name, ++$self->{clip_counter}, 'spacer';
}
package Audio::Nama;

sub new_sequence {

	my %args = @_;
	my $name = $args{name};
	my @tracks = defined $args{tracks} ? @{ $args{tracks} } : ();
	my $group = $args{group} || 'Main';
	my $mix_track = $tn{$name} || add_track($name, group => $group);
	$mix_track->set( rw 			=> MON);
	my $sequence = Audio::Nama::Sequence->new(
		name => $name,
		send_type => 'track',
		send_id	 => $name,
	);
;
	map{ $sequence->append_item($_) }
	map{ $sequence->new_clip($_)} @tracks;
	$this_sequence = $sequence;

}
sub compose_sequence {
	my ($sequence_name, $track, $markpairs) = @_;
	logpkg(__FILE__,__LINE__,'debug',"sequence_name: $sequence_name, track:", $track->name, 
			", markpairs: ",Audio::Nama::Dumper $markpairs);

	my $sequence = new_sequence( name => $sequence_name);
	logpkg(__FILE__,__LINE__,'debug',"sequence\n",Audio::Nama::Dumper $sequence);
	my @clips = map { 
		$sequence->new_clip($track, region => $_) 
	} @$markpairs;
	map{ $sequence->append_item($_) } @clips;
	$sequence
}
1
__END__