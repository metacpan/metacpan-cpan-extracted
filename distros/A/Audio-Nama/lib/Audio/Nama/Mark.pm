
# ----------- Mark ------------

package Audio::Nama::Mark;
our $VERSION = 1.0;
use Carp;
use warnings;
no warnings qw(uninitialized);
our($n, %by_name, @all);
use Audio::Nama::Log qw(logpkg);
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Object qw( 
				 name 
                 time
				 );

sub initialize {
	map{ $_->remove} Audio::Nama::Mark::all();
	@all = ();	
	%by_name = ();	# return ref to Mark by name
	$by_name{Here} = bless {}, 'Audio::Nama::HereMark';
	@Audio::Nama::marks_data = (); # for save/restore
}
sub next_id { # returns incremented 4-digit 
	$project->{mark_sequence_counter} ||= '0000';
	$project->{mark_sequence_counter}++
}
sub new {
	my $class = shift;	
	my %vals = @_;
	croak "undeclared field: @_" if grep{ ! $_is_field{$_} } keys %vals;

	# to support set_edit_points, we now allow marks to be overwritten
	#
	#croak  "name already in use: $vals{name}\n"
	#	 if $by_name{$vals{name}}; # null name returns false
	
	my $self = bless { @_ }, $class;

	#print "self class: $class, self type: ", ref $self, $/;
	if ($self->name) {
		if ( my $old = delete $by_name{$self->name} ) {
			Audio::Nama::pager("replacing previous mark at " .  $old->time);
			@all = grep{ $_->name ne $self->name } @all;
		}
		$by_name{ $self->name } = $self;
	}
	push @all, $self;
	$Audio::Nama::this_mark = $self;
	
	$self;
	
}

sub set_name {
	my $mark = shift;
	my $name = shift;
	pager("name: $name\n");
	if ( defined $by_name{ $name } ){
	carp "you attempted to assign to name already in use\n";
	}
	else {
		$mark->set(name => $name);
		$by_name{ $name } = $mark;
	}
}

sub jump_here {
	my $mark = shift;
	Audio::Nama::set_position($mark->time);
	$Audio::Nama::this_mark = $mark;
}
sub shifted_time {  # for marks within current edit
	my $mark = shift;
	return $mark->time unless $mode->{offset_run};
	my $time = $mark->time - Audio::Nama::play_start_time();
	$time > 0 ? $time : 0
}
sub remove {
	my $mark = shift;
	Audio::Nama::throw('Fades depend on this mark. Remove failed.'), return	
		if Audio::Nama::fade_uses_mark($mark->name);
	if ( $mark->name ) {
		delete $by_name{$mark->name};
	}
	@all = grep { $_->time != $mark->time } @all;
}
sub next { 
	my $mark = shift;
	Audio::Nama::next_mark();
}
sub previous {
	my $mark = shift; 
	Audio::Nama::previous_mark();
}

# -- Class Methods

sub all { sort { $a->{time} <=> $b->{time} }@all }

sub loop_start { 
	my @points = sort { $a <=> $b } 
	grep{ $_ } map{ mark_time($_)} @{$setup->{loop_endpoints}}[0,1];
	#print "points @points\n";
	$points[0];
}
sub loop_end {
	my @points =sort { $a <=> $b } 
		grep{ $_ } map{ mark_time($_)} @{$setup->{loop_endpoints}}[0,1];
	$points[1];
}
sub time_from_tag {
	my $tag = shift;
	$tag or $tag = '';
	#print "tag: $tag\n";
	my $mark;
	if ($tag =~ /\./) { # we assume raw time if decimal
		#print "mark time: ", $tag, $/;
		return $tag;
	} elsif ($tag =~ /^\d+$/){
		#print "mark index found\n";
		$mark = $Audio::Nama::Mark::all[$tag];
	} else {
		#print "mark name found\n";
		$mark = $Audio::Nama::Mark::by_name{$tag};
	}
	return undef if ! defined $mark;
	#print "mark time: ", $mark->time, $/;
	return $mark->time;
}
sub duration_from_tag {
	my $tag = shift;
	$tag or $tag = '';
	#print "tag: $tag\n";
	my $mark;
	if ($tag =~ /[\d.-]+/) { # we assume time 
		#print "mark time: ", $tag, $/;
		return $tag;
	} else {
		#print "mark name found\n";
		$mark = $Audio::Nama::Mark::by_name{$tag};
	}
	return undef if ! defined $mark;
	#print "mark time: ", $mark->time, $/;
	return $mark->time;
}
sub mark_time {
	my $tag = shift;
	my $time = time_from_tag($tag);
	return unless defined $time;
	$time -= Audio::Nama::play_start_time() if $mode->{offset_run};
	$time
}


# ---------- Mark and jump routines --------
{
package Audio::Nama;
use v5.36;
use Audio::Nama::Globals qw(:all);

sub drop_mark {
	logsub((caller(0))[3]);
	my $name = shift;
	my $here = ecasound_iam("getpos");

	if( my $mark = $Audio::Nama::Mark::by_name{$name}){
		pager("$name: a mark with this name exists already at: ", 
			colonize($mark->time));
		return
	}
	if( my ($mark) = grep { $_->time == $here} Audio::Nama::Mark::all()){
		pager( q(This position is already marked by "),$mark->name,q(") );
		 return 
	}

	my $mark = Audio::Nama::Mark->new( time => $here, 
							name => $name);

	$ui->marker($mark); # for GUI
}
sub mark { # GUI_CODE
	logsub((caller(0))[3]);
	my $mark = shift;
	my $pos = $mark->time;
	if ($gui->{_markers_armed}){ 
			$ui->destroy_marker($pos);
			$mark->remove;
		    arm_mark_toggle(); # disarm
	}
	else{ 

		set_position($pos);
	}
}

sub next_mark {
	logsub((caller(0))[3]);
	my $mark = next_mark_object();
	set_position($mark->time);
	$this_mark = $mark;
}
sub next_mark_object {
	my @marks = Audio::Nama::Mark::all();
	my $here = ecasound_iam("cs-get-position");
	for my $i ( 0..$#marks ){
		if ($marks[$i]->time - $here > 0.001 ){
			logpkg(__FILE__,__LINE__,'debug', "here: $here, future time: ", $marks[$i]->time);
			return $marks[$i];
		}
	}
}
sub previous_mark_object {
	my @marks = Audio::Nama::Mark::all();
	my $here = ecasound_iam("cs-get-position");
	for my $i ( reverse 0..$#marks ){
		if ($marks[$i]->time < $here ){
			return $marks[$i];
		}
	}
}
sub previous_mark {
	logsub((caller(0))[3]);
	my $mark = previous_mark_object();
	set_position($mark->time);
	$this_mark = $mark;
}
	
sub modify_mark {
	my ($mark, $newtime, $quiet) = @_;
	$mark->set( time => $newtime );
	! $quiet && do {
	pager($mark->name, ": set to ", d2( $newtime), "\n");
	pager("adjusted to ",$mark->time, "\n") 
		if $mark->time != $newtime;
	};
	set_position($mark->time);
	request_setup();
}
#  D: delete_current_mark
#  .: drop_snip_mark
sub bump_mark_minus_1 { }
sub bump_mark_plus_1 { }
sub bump_mark_minus_point_1 { }
sub bump_mark_plus_point_1 { }
sub bump_mark_minus_point_01 { }
sub bump_mark_plus_point_01 { }


## jump playback head position

sub jump_to_start { 
	logsub((caller(0))[3]);
	return if Audio::Nama::ChainSetup::really_recording();
	jump( 0 );
}
sub jump_to_end { 
	logsub((caller(0))[3]);
	# ten seconds shy of end
	return if Audio::Nama::ChainSetup::really_recording();
	my $end = ecasound_iam('cs-get-length') - $config->{seek_end_margin} ;  
	jump($end);
} 
sub jump {
	return if Audio::Nama::ChainSetup::really_recording();
	my $delta = shift;
	logsub((caller(0))[3]);
	my $here = ecasound_iam('getpos');
	logpkg(__FILE__,__LINE__,'debug', "delta: $delta, here: $here");
	my $new_pos = $here + $delta;
	if ( $setup->{audio_length} )
	{
		$new_pos = $new_pos < $setup->{audio_length} 
			? $new_pos 
			: $setup->{audio_length} - 10
	}
	set_position_with_fade( $new_pos );
}
sub set_position_with_fade { fade_around(\&_set_position, @_) }

sub _set_position {
	logsub((caller(0))[3]);

    return if Audio::Nama::ChainSetup::really_recording(); # don't allow seek while recording

    my $seconds = shift;
    my $coderef = sub{ ecasound_iam("setpos $seconds") };

	$jack->{jackd_running} 
		?  Audio::Nama::stop_do_start( $coderef, $jack->{seek_delay} )
		:  $coderef->();

	update_clock_display();
}

# used by hotkeys

#sub previous_mark {}
#sub next_mark {}
sub delete_current_mark {}
#sub drop_mark {}
sub bump_mark_forward_1 {}
sub bump_mark_forward_10 {}
sub bump_mark_back_1 {}
sub bump_mark_back_10 {}
#sub jump_to_start {}
#sub jump_to_end {}
sub jump_pos_forward_1 {}
sub jump_pos_forward_10 {}
sub jump_pos_back_1 {}
sub jump_pos_back_10 {}
sub jump_replay {}

sub forward {
	my $delta = shift;
	my $here = ecasound_iam('getpos');
	my $new = $here + $delta;
	set_position( $new );
}

sub rewind {
	my $delta = shift;
	forward( -$delta );
}
sub jump_forward {
	my $multiplier = shift;
	 forward( $multiplier * $text->{hotkey_playback_jumpsize})
	}
sub jump_backward { jump_forward( - shift()) }

	
} # end package
{ package Audio::Nama::HereMark;
our $VERSION = 1.0;
our @ISA = 'Audio::Nama::Mark';
our $last_time;
sub name { 'Here' }
sub time { Audio::Nama::ecasound_iam('cs-connected') ? ($last_time = Audio::Nama::ecasound_iam('getpos')) : $last_time } 
}

{ package Audio::Nama::ClipMark;
use v5.36;
our $VERSION = 1.0;
our @ISA = 'Audio::Nama::Mark';


}

{ package Audio::Nama::TempoMark;

	our $VERSION = 1.0;
	use v5.36;
	use Audio::Nama::Log qw(logpkg);
	use Audio::Nama::Globals qw(:all);
	our @ISA = 'Audio::Nama::Mark';
	use SUPER; 
	use Audio::Nama::Object qw( 
					 name 
					bars	
					beats
					ticks
					 );
}

1;
__END__