# ---------- Track -----------
#
package Audio::Nama;
{
package Audio::Nama::Track;
use Role::Tiny::With;
with 'Audio::Nama::Wav',
	 'Audio::Nama::WavModify',
	 'Audio::Nama::TrackRegion',
	 'Audio::Nama::TrackIO',
	 'Audio::Nama::TrackComment',
	 'Audio::Nama::TrackEffect',
	 'Audio::Nama::TrackLatency',
	 'Audio::Nama::TrackWaveform',
	 'Audio::Nama::EffectNickname',
	 'Audio::Nama::BusUtil';
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logpkg logsub);
use Audio::Nama::Effect  qw(fxn);
use List::MoreUtils qw(first_index);
use Try::Tiny;
use v5.36;
our $VERSION = 1.0;
use Carp qw(carp cluck croak);
use File::Copy qw(copy);
use File::Slurp;
use Memoize qw(memoize unmemoize);
no warnings qw(uninitialized redefine);

use Audio::Nama::Util qw(freq input_node dest_type dest_string join_path);
use Audio::Nama::Assign qw(json_out);
use vars qw($n %by_name @by_index %track_names %by_index);
use Audio::Nama::Object qw(
					class 			
					is_mix_track	
					n   			
					name
					group 			
					rw				
					version         
					midi_versions		
					width			
					ops 			
					vol				
					pan				
					fader			
					latency_op		
					offset			
					old_vol_level	
					old_pan_level
					playat			
					region_start	
					region_end
					modifiers		
					looping			
					hide			
					source_id		
					source_type		
					last_source		
					send_id			
					send_type
					target			
					project			
					forbid_user_ops	
					engine_group
					current_edit    

);

# Note that ->vol return the effect_id 
# ->old_volume_level is the level saved before muting
# ->old_pan_level is the level saved before pan full right/left
# commands

initialize();

### class subroutines

sub initialize {
	$n = 0; 	# incrementing numeric key
	%by_index = ();	# return ref to Track by numeric key
	%by_name = ();	# return ref to Track by name
	%track_names = (); 
}

sub idx { # return first free track index
	my $n = 0;
	while (++$n){
		return $n if not $by_index{$n}
	}
}
sub new {
	# returns a reference to an object 
	#
	# tracks are indexed by:
	# (1) name and 
	# (2) by an assigned index that is used as chain_id
	#     the index may be supplied as a parameter
	#
	# 

	my $class = shift;
	my %vals = @_;
	my $novol = delete $vals{novol};
	my $nopan = delete $vals{nopan};
	my $restore = delete $vals{restore};
	say "restoring track $vals{name}" if $restore;
	my @undeclared = grep{ ! $_is_field{$_} } keys %vals;
    croak "undeclared field: @undeclared" if @undeclared;
	
	# silently return if track already exists
	# why not return track? TODO
	
	return if $by_name{$vals{name}};

	my $n = $vals{n} || idx(); 
	my $object = bless { 


		## 		defaults ##
					class	=> $class,
					name 	=> "Audio_$n", 
					group	=> 'Main', 
					n    	=> $n,
					ops     => [],
					width => 1,
					vol  	=> undef,
					pan 	=> undef,
					rw		=> 'MON',

					modifiers 		=> q(), # start, reverse, audioloop, playat
					looping 		=> undef, # do we repeat our sound sample
					source_type 	=> q(soundcard),
					source_id   	=> "1",
					send_type 		=> undef,
					send_id   		=> undef,
					old_vol_level	=> undef,

					@_ 			}, $class;

	$track_names{$vals{name}}++;
	$by_index{$n} = $object;
	$by_name{ $object->name } = $object;
	Audio::Nama::add_pan_control($n) unless $nopan or $restore;
	Audio::Nama::add_volume_control($n) unless $novol or $restore;

	$Audio::Nama::this_track = $object;
	$Audio::Nama::ui->track_gui($object->n) unless $object->hide;
	logpkg(__FILE__,__LINE__,'debug',$object->name, ": ","newly created track",$/,json_out($object->as_hash));
	$object;
}


### object methods

sub snapshot {
	my $track = shift;
	my $fields = shift;
	my %snap; 
	my $i = 0;
	for(@$fields){
		$snap{$_} = $track->$_;
	}
	\%snap;
}


# create an edge representing sound source

# blows up when I move it to TrackIO

sub input_path { 

	my $track = shift;

	# the corresponding bus handles input routing for mix tracks
	# so they don't need to be connected here
	
	return() if $track->is_mixing and ! $track->play;

	# the track may route to:
	# + another track
	# + an external source (soundcard or JACK client)
	# + a WAV file

	if($track->source_type eq 'track'){ ($track->source_id, $track->name) } 

	elsif($track->rec_status =~ /REC|MON/){ 
		(input_node($track->source_type), $track->name) } 

	elsif($track->play and ! $mode->doodle){
		(input_node('wav'), $track->name) 
	}
}

# remove track object and all effects

sub remove {
	my $track = shift;
	my $n = $track->n;
	$ui->remove_track_gui($n); 
	# remove corresponding fades
	map{ $_->remove } grep { $_->track eq $track->name } values %Audio::Nama::Fade::by_index;
	# remove effects
 	map{ Audio::Nama::remove_effect($_) } @{ $track->ops };
 	delete $by_index{$n};
 	delete $by_name{$track->name};
}


# Modified from Object.p to save class
# should this be used in other classes?
sub as_hash {
	my $self = shift;
	my $class = ref $self;
	my %guts = %{ $self };
	$guts{class} = $class; # make sure we save the correct class name
	return \%guts;
}
sub input_object {
	my $track = shift;
	$Audio::Nama::IO::by_name{$track->name}->{input}
}
sub output_object {
	my $track = shift;
	$Audio::Nama::IO::by_name{$track->name}->{output}
}
sub rec_setup_script { 
	my $track = shift;
	join_path(Audio::Nama::project_dir(), $track->name."-rec-setup.sh")
}
sub rec_cleanup_script { 
	my $track = shift;
	join_path(Audio::Nama::project_dir(), $track->name."-rec-cleanup.sh")
}
sub current_edit { $_[0]->{current_edit}//={} }
sub is_mixing {
	my $track = shift;
	$track->is_mixer and ($track->mon or $track->rec)
}
sub bus { $bn{$_[0]->group} }

{ my %system_track = map{ $_, 1} qw( Main Mixdown Eq Low
Mid High Boost midi_record_buffer);
sub is_user_track { ! $system_track{$_[0]->name} }
sub is_system_track { $system_track{$_[0]->name} } 
}

sub engine_group {
	my $track = shift;
	$track->{engine_group} || $Audio::Nama::config->{ecasound_engine_name}
}
sub engine {
	my $track = shift;
	$en{$track->engine_group}
}
sub select_track {
		my $track = shift;
		$Audio::Nama::this_track = $track;
		$this_engine->current_chain( $track->n );
		# XXX wrong engine for MIDI track
		Audio::Nama::set_current_bus();
}
sub is_selected { $Audio::Nama::this_track->name eq $_[0]->name }

sub rec  { $_[0]->rec_status eq REC }
sub mon  { $_[0]->rec_status eq MON }
sub play { $_[0]->rec_status eq PLAY}
sub off  { $_[0]->rec_status eq OFF }

sub current_midi {}
sub fades { grep { $_->{track} eq $_[0]->name } values %Audio::Nama::Fade::by_index  }

} # end package


# subclasses


{
package Audio::Nama::SimpleTrack; # used for Main track
use Audio::Nama::Globals qw(:all);
use v5.36; use Carp; use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
use SUPER;
no warnings qw(uninitialized redefine);
our @ISA = 'Audio::Nama::Track';
sub rec_status {
	my $track = shift;
 	$track->rw ne OFF ? MON : OFF 
}
sub destination {
	my $track = shift; 
	return 'Mixdown' if $tn{Mixdown}->rec;
	return $track->SUPER() if $track->rec_status ne OFF
}
#sub rec_status_display { $_[0]->rw ne OFF ? PLAY : OFF }
sub activate_bus {}
}
{
package Audio::Nama::MasteringTrack; # used for mastering chains 
use Audio::Nama::Globals qw(:all);
use v5.36; use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
no warnings qw(uninitialized redefine);
our @ISA = 'Audio::Nama::SimpleTrack';

sub rec_status{
	my $track = shift;
 	return OFF if $track->engine_group ne $en{$Audio::Nama::config->{ecasound_engine_name}}->name;
	$mode->mastering ? MON :  OFF;
}
sub source_status {}
sub group_last {0}
sub version {0}
}
{
package Audio::Nama::EarTrack; # for submix helper tracks
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Util qw(dest_string);
use v5.36; use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
use SUPER;
no warnings qw(uninitialized redefine);
our @ISA = 'Audio::Nama::SlaveTrack';
sub destination {
	my $track = shift;
	my $bus = $track->bus;
	dest_string($bus->send_type,$bus->send_id, $track->width);
}
sub source_status { $tn{$_[0]->target}->source_status }
sub rec_status { $_[0]->{rw} }
sub width { $_[0]->{width} }
}
{
package Audio::Nama::SlaveTrack;
use Audio::Nama::Globals qw(:all);
use v5.36; use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
no warnings qw(uninitialized redefine);
our @ISA = 'Audio::Nama::Track';
sub width { $tn{$_[0]->target}->width }
sub rec_status { $tn{$_[0]->target}->rec_status }
sub full_path { $tn{$_[0]->target}->full_path} 
sub playback_version { $tn{$_[0]->target}->playback_version} 
sub source_type { $tn{$_[0]->target}->source_type}
sub source_id { $tn{$_[0]->target}->source_id}
sub source_status { $tn{$_[0]->target}->source_status }
sub send_type { $tn{$_[0]->target}->send_type }
sub send_id {   $tn{$_[0]->target}->send_id   }

sub dir { $tn{$_[0]->target}->dir }
}
{
package Audio::Nama::BoostTrack; 
use Audio::Nama::Globals qw(:all);
use v5.36; use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
no warnings qw(uninitialized redefine);
our @ISA = 'Audio::Nama::Track';
sub rec_status{
	my $track = shift;
	$mode->mastering ? MON :  OFF;
}
sub send_type { $tn{Main}->send_type }
sub send_id { $tn{Main}->send_id }
}
{
package Audio::Nama::CacheRecTrack;
our $VERSION = 1.0;
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logpkg);
our @ISA = qw(Audio::Nama::SlaveTrack);
sub current_version {
	my $track = shift;
	my $target = $tn{$track->target};
	$target->last + 1
}
sub current_wav {
	my $track = shift;
		$tn{$track->target}->name . '_' . $track->current_version . '.wav'
}
sub full_path { my $track = shift; Audio::Nama::join_path( $track->dir, $track->current_wav) }
}
{
package Audio::Nama::MixDownTrack; 
our $VERSION = 1.0;
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logpkg);
use SUPER;
our @ISA = qw(Audio::Nama::Track);
sub current_version {	
	my $track = shift;
	my $last = $track->last;
	my $status = $track->rec_status;
	#logpkg(__FILE__,__LINE__,'debug', "last: $last status: $status");
	if 	($status eq REC){ return ++$last}
	elsif ( $status eq PLAY){ return $track->playback_version } 
	else { return 0 }
}
sub source_status { 
	my $track = shift; 
	return 'Main' if $track->rec;
	my $super = $track->super('source_status');
	$super->($track)
}
sub destination {
	my $track = shift; 
	$tn{Main}->destination if $track->play
}
sub rec_status {
 	my $track = shift;
	$track->rw
# 	return REC if $track->rw eq REC;
# 	Audio::Nama::Track::rec_status($track);
}
sub forbid_user_ops { 1 }
}
{
package Audio::Nama::EditTrack; use Carp qw(carp cluck);
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
our @ISA = 'Audio::Nama::Track';
our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;
	logpkg(__FILE__,__LINE__,'debug', $self->name, ": args @_");
    # get tail of method call
    my ($call) = $AUTOLOAD =~ /([^:]+)$/;
	$Audio::Nama::Edit::by_name{$self->name}->$call(@_);
}
sub DESTROY {}
sub current_version {	
	my $track = shift;
	my $last = $track->last;
	my $status = $track->rec_status;
	#logpkg(__FILE__,__LINE__,'debug', "last: $last status: $status");
	if 	($status eq REC){ return ++$last}
	elsif ( $status eq PLAY){ return $track->playback_version } 
	else { return 0 }
}
sub playat_time {
	logpkg(__FILE__,__LINE__,'logcluck',$_[0]->name . "->playat_time");
	$_[0]->play_start_time
}
}
{
package Audio::Nama::VersionTrack;
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
our @ISA ='Audio::Nama::Track';
sub set_version {}
sub versions { [$_[0]->version] }
}
{
package Audio::Nama::Clip;

# Clips are the units of audio used to 
#  to make sequences. 

# A clip is created from a track. Clips extend the Track
# class in providing a position which derives from the
# object's ordinal position in an array (clips attribute) of
# the parent sequence object.
 
# Clips differ from tracks in that clips
# their one-based position (index) in the sequence items array.
# index is one-based.

use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
our @ISA = qw( Audio::Nama::VersionTrack Audio::Nama::Track );

sub sequence { my $self = shift; $Audio::Nama::bn{$self->group} };

sub index { my $self = shift; my $i = 0;
	for( @{$self->sequence->items} ){
		$i++;
		return $i if $self->name eq $_
	}
}
sub predecessor {
	my $self = shift;
	$self->sequence->clip($self->index - 1)
}
sub duration {
	my $self = shift;
	$self->{duration} 
		? Audio::Nama::Mark::duration_from_tag($self->{duration})
		: $self->is_region 
			? $self->region_end_time - $self->region_start_time 
			: $self->wav_length;
}
sub endpoint { 
	my $self = shift;
	$self->duration + ( $self->predecessor ?  $self->predecessor->endpoint : 0 )
}
sub playat_time {
	my $self = shift;
	my $previous = $self->predecessor;
	$previous ? $previous->endpoint : 0
}
sub rec_status { $_[0]->version ? PLAY : OFF } 

# we currently are not compatible with offset run mode
# perhaps we can enforce OFF status for clips under 
# offset run mode

} # end package
{ 
package Audio::Nama::Spacer;
our $VERSION = 1.0;
our @ISA = 'Audio::Nama::Clip';
use SUPER;
use Audio::Nama::Object qw(duration);
sub rec_status { OFF }
sub new { 
	my ($class,%args) = @_;

	# remove args we will process
	my $duration = delete $args{duration};

	# give the remainder to the superclass constructor
	@_ = ($class, %args);
	my $self = super();
	#logpkg(__FILE__,__LINE__,'debug',"new object: ", json_out($self->as_hash));
	#logpkg(__FILE__,__LINE__,'debug', "items: ",json_out($items));

	# set the args removed above
	$self->{duration} = $duration;
	$self;
}
} # end package
{ 
package Audio::Nama::WetTrack; # for inserts
use Audio::Nama::Globals qw(:all);
use v5.36; use Audio::Nama::Log qw(logpkg);
our $VERSION = 1.0;
our @ISA = 'Audio::Nama::SlaveTrack';
}

{
package Audio::Nama::MidiTrack; 
use Audio::Nama::Globals qw(:all);
use v5.36;
our $VERSION = 1.0;
use SUPER;
use Audio::Nama::Log qw(logpkg);
our @ISA = qw(Audio::Nama::Track);
sub new {
	my ($class, %args) = @_;
	my $self = super();
	$self
}
# TODO enable
sub mute {   
	my $track = shift;
	if ( $track->exists_midi )
	{
		Audio::Nama::midish_cmd( 'mute '  . $_[0]->current_midi ) 
	}
}
sub unmute { 
	my $track = shift;
	if ( $track->exists_midi )
	{
		# mute unselected versions
		map{ Audio::Nama::midish_cmd( 'mute '. midi_version_name($track->name, $_) ) }
		grep{ $_ != $track->version } @{$track->versions};

		Audio::Nama::midish_cmd( 'unmute '  . $_[0]->current_midi ) 
	}
}
sub rw_set {
	my $track = shift;
	my ($bus, $setting) = @_;
	$track->{rw} = uc $setting;
}
sub exists_midi {
	my $track = shift;
	my ($tlist) = Audio::Nama::midish_cmd('print [tlist]');
	$tlist =~ s/[}{]//g;
	my ($match) = grep{$_ eq $track->current_midi} split " ", $tlist;
}
sub rec_status { 
		my $self = shift;
		if	 ( $self->rw eq REC and	$self->is_selected )							{ REC  } 
		elsif( $self->rw eq REC and	! $self->is_selected )							{ PLAY } 
		elsif( $self->rw eq PLAY )													{ PLAY }
		else																		{ OFF  }
}
sub versions { $_[0]->{midi_versions} }


sub select_track {
		my $track = shift;
		$Audio::Nama::this_track = $track;
		$track->unmute;
		Audio::Nama::set_current_bus();
}
sub current_midi {
	# current MIDI track
	# provides the name of the midish track corresponding to the selected version
	# example: synth_2, for track synth, version 2
	# analagous to current_wav() for audio track which would output synth_2.wav
	 
	my $track = shift;
	
	if 	($track->rec_status eq REC)
	{ 
		midi_version_name($track->name, $track->current_version)
	} 
	elsif ( $track->rec_status eq PLAY)
	{ 
		midi_version_name($track->name, $track->playback_version)
	} 
	else 
	{ 
		logpkg(__FILE__,__LINE__,'debug', "track ", $track->name, ": no current version") ;
		undef; 
	}
}
sub set_io {
	my $track = shift;
	my ($direction, $id) = @_;
	my $type = 'midi';
	
	my $type_field = $direction."_type";
	my $id_field   = $direction."_id";

	# respond to query
	if ( ! $id ){ return $track->$type_field ? $track->$id_field : undef }

	# set values, returning new setting
	$track->set($type_field => $type);
	$track->set($id_field => $id);
} 
sub set_rw {
	my $track = shift;
	my ($bus, $setting) = @_;
	Audio::Nama::throw("can't set MIDI track to MON. Setting is unchanged"), return if $setting eq MON;
	$track->{rw} = $setting;
	# mute all versions
	#$logic{$setting}->($bus, $setting);
}
sub create_midi_version {
	my $track = shift;
	my $n = shift;
	Audio::Nama::add_midi_track(midi_version_name($track->name, $n), hide => 1);
}
sub set_version {
	my ($track, $n) = @_;
	my $name = $track->name;
	if ($n == 0){
		Audio::Nama::pager("$name: version set to zero, following bus default\n");
		$track->set(version => $n)
	} elsif ( grep{ $n == $_ } @{$track->versions} ){
		Audio::Nama::pager("$name: anchoring version $n\n");
		$track->set(version => $n);
	} else { 
		Audio::Nama::throw("$name: version $n does not exist, skipping.\n")
	}
}
sub midi_version {
	my $track = shift;
	join '_', $track->name, $track->version if $track->version
}

}

1;
__END__