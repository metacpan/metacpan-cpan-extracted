# ------------- Mute and Solo routines -----------

package Audio::Nama;
use v5.36;

sub mute {
	return if $config->{opts}->{F};
	return if $tn{Main}->rw eq OFF or Audio::Nama::ChainSetup::really_recording();
	$tn{Main}->mute;
}
sub unmute {
	return if $config->{opts}->{F};
	return if $tn{Main}->rw eq OFF or Audio::Nama::ChainSetup::really_recording();
	$tn{Main}->unmute;
}
sub fade_around {
	my ($coderef, @args) = @_;
	if( $this_engine->started() )
	{
		mute();
		$coderef->(@args);
		unmute();
	}
	else { $coderef->(@args) }
}
sub solo {
	my @args = @_;

	# get list of already muted tracks if I haven't done so already
	
	if ( ! @{$fx->{muted}} ){
		@{$fx->{muted}} = map{ $_->name } grep{ defined $_->old_vol_level} user_tracks() }

	logpkg(__FILE__,__LINE__,'debug', join " ", "already muted:", sub{map{$_->name} @{$fx->{muted}}});

	# convert bunches to tracks
	my @names = map{ bunch_tracks($_) } @args;

	# use hashes to store our list
	
	my %to_mute;
	my %not_mute;
	
	# get dependent tracks
	
	my @dependents = map{ $tn{$_}->bus_tree() } @names;

	# store solo tracks and dependent tracks that we won't mute

	map{ $not_mute{$_}++ } @names, @dependents;

	# find all siblings tracks not in depends list

	# - get buses list corresponding to our non-muting tracks
	
	my %buses;
	$buses{Main}++; 				# we always want Main
	
	map{ $buses{$_}++ } 			# add to buses list
	map { $tn{$_}->group } 			# corresponding bus (group) names
	keys %not_mute;					# tracks we want

	# - get sibling tracks we want to mute

	map{ $to_mute{$_}++ }			# add to mute list
	grep{ ! $not_mute{$_} }			# those we *don't* want
	map{ $bn{$_}->tracks }			# tracks list
	keys %buses;					# buses list

	# mute all tracks on our mute list (do we skip already muted tracks?)
	
	do_many_tracks( { tracks => [ keys %to_mute ], method => 'mute' } );

	# unmute all tracks on our wanted list
	
	do_many_tracks( { tracks => [ keys %not_mute ], method => 'unmute' } );
	
	$mode->{soloing} = 1;
}

sub nosolo {
	# unmute all except in @{$fx->{muted}} list

	# unmute all tracks
	do_many_tracks( { tracks => [ map{$_->name} user_tracks() ], method => 'unmute' } );

	# re-mute previously muted tracks
	if (@{$fx->{muted}}){
		do_many_tracks( { tracks => [ @{$fx->{muted}} ], method => 'mute' } );
	}

	# remove listing of muted tracks
	@{$fx->{muted}} = ();
	
	$mode->{soloing} = 0;
}
sub all {

	# unmute all tracks
	do_many_tracks( { tracks => [ Audio::Nama::Track::user() ], method => 'unmute' } );

	# remove listing of muted tracks
	@{$fx->{muted}} = ();
	
	$mode->{soloing} = 0;
}

sub do_many_tracks {
	# args: { tracks => [ track objects ], method => method_name }
	my $args = shift;
	my $method = $args->{method};
	my $delay = $args->{delay} || $config->{engine_muting_time};
	map{ $tn{$_}->$method('nofade'); sleeper($delay) } @{$args->{tracks}};
}

1;
__END__