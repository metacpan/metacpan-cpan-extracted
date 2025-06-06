package Audio::Nama::EcasoundRun;
use Role::Tiny;
use v5.36;
our $VERSION = 1.0;
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logpkg logsub);
use Audio::Nama::Util qw(timer start_event stop_event);
sub start { 
	package Audio::Nama;
	my $self = shift; 

	$self->valid_setup
		or throw("\nAudio engine is not configured. Cannot start.\n"),return;


	# use gradual unmuting to avoid pop on start
	# 
	#
	# mute unless recording
	# start
	# wait 0.5s
	# unmute
	# start heartbeat
	# report engine status
	# sleep 1s
	#

	pager("\n\nStarting at ". current_position()) unless $quiet;
	schedule_wraparound();
	mute();
	$self->start_command;
	$self->{started}++;
	start_midi_transport() if midi_run_ready();

	# limit engine run time if we are in mixdown or edit mode, 
	# or if requested by user, set timer to specified time
	# defaulting to the result of cs-get-length
	limit_processing_time( ($setup->{runtime_limit} || $setup->{audio_length}) + $setup->{extra_run_time}) 
		if mixing_only() 
		or edit_mode() 
		or defined $setup->{runtime_limit};
		# TODO and live processing
 	#$project->{events}->{post_start_unmute} = timer(0.5, 0, sub{unmute()});
	sleeper(0.5);
	unmute();
	sleeper(0.5);
	$ui->set_engine_mode_color_display();
	start_heartbeat();
	engine_status() unless $quiet;
}
sub stop {
	package Audio::Nama;
	my $self = shift;
	if ($self->running())
	{
	# Since the playback position advances slightly during
	# the fade, we restore the position to exactly where the
	# stop command was issued.
	
	my $pos;
	$pos = $self->ecasound_iam('getpos') if ! Audio::Nama::ChainSetup::really_recording();
	mute();
	$self->stop_command;
	disable_length_timer();
	if ( ! $quiet ){
		sleeper(0.5);
		engine_status(current_position(),2,0);
	}
	unmute();
	stop_heartbeat();
	$ui->project_label_configure(-background => $gui->{_old_bg});

	# restore exact position transport stop command was issued
	
	set_position($pos) if $pos
	}
}
sub stop_command { $_[0]->ecasound_iam('stop-sync') }
sub start_command { $_[0]->ecasound_iam('start') }
### routines defined in the root namespace

package Audio::Nama;
use v5.36; use Carp;
no warnings 'uninitialized';
use Audio::Nama::Util qw(process_is_running);

sub mixing_only {
	my $i;
	my $am_mixing;
	for (Audio::Nama::ChainSetup::really_recording()){
		$i++;
		$am_mixing++ if /Mixdown/;
	}
	$i == 1 and $am_mixing
}

sub sync_transport_position { }

sub midish_running { $setup->{midish_running} }
	
sub toggle_transport { $this_engine->running() ?  stop_transport() : start_transport() }

sub disconnect_transport {
	return if $this_engine->running;
	teardown_engine();
}
sub engine_is {
	my $pos = shift;
	"\n\nEngine is ". $this_engine->ecasound_iam("engine-status"). ( $pos ? " at $pos" : "" )
}
sub engine_status { 
	my ($pos, $before_newlines, $after_newlines) = @_;
	pager("\n" x $before_newlines, engine_is($pos), "\n" x $after_newlines);
}
sub current_position { 
	my $pos = $this_engine->ecasound_iam("getpos"); 
	colonize(int($pos || 0)) 
}
sub start_heartbeat {
 	start_event(poll_engine => timer(0, 1, \&Audio::Nama::heartbeat));
	$ui->setup_playback_indicator();
}
sub stop_heartbeat {
	# the following test avoids double-tripping rec_cleanup()
	# following manual stop
	return unless $project->{events}->{poll_engine};
	stop_event('poll_engine');
	stop_event('update_playback_position_display');
	$ui->reset_engine_mode_color_display();
	rec_cleanup() 
}
sub heartbeat {

	#	print "heartbeat fired\n";

	my $here   = $this_engine->ecasound_iam("getpos");
	my $status = $this_engine->ecasound_iam('engine-status');
	if( $status =~ /finished|error/ ){
		engine_status(current_position(),2,1);
		revise_prompt();
		stop_heartbeat(); 
		sleeper(0.2);
		delete $this_engine->{started};
		set_position(0);
	}
	#print join " ", $status, colonize($here), $/;
	my ($start, $end);
	$start  = Audio::Nama::Mark::loop_start();
	$end    = Audio::Nama::Mark::loop_end();
	schedule_wraparound() 
		if $mode->{loop_enable} 
		and defined $start 
		and defined $end 
		and ! Audio::Nama::ChainSetup::really_recording();

	update_clock_display();

}

sub update_clock_display { 
	$ui->clock_config(-text => current_position());
}
sub schedule_wraparound {

	return unless $mode->{loop_enable};
	my $here   = $this_engine->ecasound_iam("getpos");
	my $start  = Audio::Nama::Mark::loop_start();
	my $end    = Audio::Nama::Mark::loop_end();
	my $diff = $end - $here;
	logpkg(__FILE__,__LINE__,'debug', "here: $here, start: $start, end: $end, diff: $diff");
	if ( $diff < 0 ){ # go at once
		set_position($start);
		cancel_wraparound();
	} elsif ( $diff < 3 ) { #schedule the move
		wraparound($diff, $start);
	}
}
sub cancel_wraparound {
	stop_event('wraparound');
}
sub limit_processing_time {
	my $length = shift;
 	start_event(processing_time => timer($length, 0, sub { Audio::Nama::stop_transport(); print prompt() }));
}
sub disable_length_timer {
	stop_event('processing_time');
	undef $setup->{runtime_limit};
}
sub wraparound {
	my ($diff, $start) = @_;
	#print "diff: $diff, start: $start\n";
	stop_event('wraparound');
	start_event(wraparound => timer($diff,0, sub{set_position($start)}));
}
sub stop_do_start {
	my ($coderef, $delay) = @_;
	$this_engine->started() ?  _stop_do_start( $coderef, $delay)
					 : $coderef->()

}
sub _stop_do_start {
	my ($coderef, $delay) = @_;
		$this_engine->stop_command();
		my $result = $coderef->();
		sleeper($delay) if $delay;
		$this_engine->start_command();
		$result
}
sub restart_ecasound {
	pager_newline("killing ecasound processes @{$en{$Audio::Nama::config->{ecasound_engine_name}}->{pids}}");
	kill_my_ecasound_processes();
	pager_newline(q(restarting Ecasound engine - your may need to use the "arm" command));	
	initialize_ecasound_engine();
	request_setup();
	reconfigure_engine();
}
sub kill_my_ecasound_processes {
	my @signals = (15, 9);
	map{ kill $_, @{$en{$Audio::Nama::config->{ecasound_engine_name}}->{pids}}; sleeper(1)} @signals;
}


1