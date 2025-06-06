package Audio::Nama::EcasoundSetup;
use Role::Tiny;
use v5.36;
our $VERSION = 1.0;
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Log qw(logpkg logsub);
sub setup { 
	package Audio::Nama;
	no warnings 'uninitialized';
	my $self = shift;
	# return 1 if successful
	# catch errors from generate_setup_try() and cleanup
	logsub((caller(0))[3]);

	# extra argument (setup code) will be passed to generate_setup_try()
	my (@extra_setup_code) = @_;

	# save current track
	local $this_track;

	# prevent engine from starting an old setup
	
	ecasound_iam('cs-disconnect') if ecasound_iam('cs-connected');

	Audio::Nama::ChainSetup::remove_temporary_tracks();
	refresh_wav_cache(); # check if someone has snuck in some files
	find_duplicate_inputs(); # we will warn the user later
	Audio::Nama::ChainSetup::initialize();
	
	# catch errors unless testing (no-terminal option)
	local $@ unless $config->{opts}->{T}; 
	track_memoize(); 			# cache track methods 
	my $success = $config->{opts}->{T}      # don't catch errors during testing 
		?  Audio::Nama::ChainSetup::generate_setup_try(@extra_setup_code)
		:  eval { Audio::Nama::ChainSetup::generate_setup_try(@extra_setup_code) }; 
	track_unmemoize(); 			# clear methods cache
	if ($@){
		throw("error caught while generating setup: $@");
		Audio::Nama::ChainSetup::initialize();
		return
	}
	$success;
}

### legacy ecasound support routines in root namespace 

package Audio::Nama;
use v5.36;
no warnings 'uninitialized';
sub find_duplicate_inputs { # in Main bus only

	%{$setup->{tracks_with_duplicate_inputs}} = ();
	%{$setup->{inputs_used}} = ();
	logsub((caller(0))[3]);
	map{	my $source = $_->source;
			$setup->{tracks_with_duplicate_inputs}->{$_->name}++ if $setup->{inputs_used}->{$source} ;
		 	$setup->{inputs_used}->{$source} //= $_->name;
	} 
	grep { $_->rw eq REC }
	map{ $tn{$_} }
	$bn{Main}->tracks(); # track names;
}
sub load_ecs {
	my $setup = shift;
	#say "setup file: $setup " . ( -e $setup ? "exists" : "");
	return unless -e $setup;
	#say "passed conditional";
	teardown_engine();
	ecasound_iam("cs-load $setup");
	ecasound_iam("cs-select $setup"); # needed by Audio::Ecasound, but not Net-ECI !!
	my $result = ecasound_iam("cs-selected");
	$setup eq $result or throw("$result: failed to select chain setup");
	logpkg(__FILE__,__LINE__,'debug',sub{map{ecasound_iam($_)} qw(cs es fs st ctrl-status)});
	1;
}
sub teardown_engine {
	ecasound_iam("cs-disconnect") if ecasound_iam("cs-connected");
	ecasound_iam("cs-remove") if ecasound_iam("cs-selected");
}

sub arm {
	logsub((caller(0))[3]);
	exit_preview_modes();
	request_setup();
	reconfigure_engine();
}

# substitute all live inputs by clock-sync'ed 
# Ecasound null device 'rtnull'

sub arm_rtnull {

local %Audio::Nama::IO::io_class = qw(
	null_in					Audio::Nama::IO::from_null
	null_out				Audio::Nama::IO::to_null
	soundcard_in 			Audio::Nama::IO::from_rtnull
	soundcard_out 			Audio::Nama::IO::to_rtnull
	wav_in 					Audio::Nama::IO::from_wav
	wav_out 				Audio::Nama::IO::to_wav
	loop_source				Audio::Nama::IO::from_loop
	loop_sink				Audio::Nama::IO::to_loop
	jack_manual_in			Audio::Nama::IO::from_rtnull
	jack_manual_out			Audio::Nama::IO::to_rtnull
	jack_ports_list_in		Audio::Nama::IO::from_rtnull
	jack_ports_list_out		Audio::Nama::IO::to_rtnull
	jack_multi_in			Audio::Nama::IO::from_rtnull
	jack_multi_out			Audio::Nama::IO::to_rtnull
	jack_client_in			Audio::Nama::IO::from_rtnull
	jack_client_out			Audio::Nama::IO::to_rtnull
	);

arm();

}
sub something_to_run { $en{ecasound}->valid_setup or midi_run_ready()  }

sub midi_run_ready { $config->{use_midi} and $en{midish} and $en{midish}->is_active }

sub connect_transport {
	logsub((caller(0))[3]);
	remove_riff_header_stubs();
	register_other_ports(); # we won't see Nama ports since Nama hasn't started
	load_ecs($file->chain_setup) or Audio::Nama::throw("failed to load chain setup"), return;
	$this_engine->valid_setup()
		or throw("Invalid chain setup, engine not ready."),return;
	find_op_offsets(); 
	setup_fades();
	apply_ops();
	ecasound_iam('cs-connect');
		#or throw("Failed to connect setup, engine not ready"),return;
	my $status = ecasound_iam("engine-status");
	if ($status ne 'not started'){
		throw("Invalid chain setup, cannot connect engine.\n");
		return;
	}
	ecasound_iam('engine-launch');
	$status = ecasound_iam("engine-status");
	if ($status ne 'stopped'){
		throw("Failed to launch engine. Engine status: $status\n");
		return;
	}
	$setup->{audio_length} = ecasound_iam('cs-get-length'); # returns zero if unknown
	sync_effect_parameters();
	register_own_ports();
	$ui->length_display(-text => colonize($setup->{audio_length}));
	ecasound_iam("cs-set-length $setup->{audio_length}") if $tn{Mixdown}->rec_status eq REC and $setup->{audio_length};
	$ui->clock_config(-text => colonize(0));
	sleeper(0.2); # time for ecasound engine to launch

	# set delay for seeking under JACK
	# we use a heuristic based on the number of tracks
	# but it should be based on the number of PLAY tracks
	
	my $track_count; map{ $track_count++ } Audio::Nama::ChainSetup::engine_tracks();
	$jack->{seek_delay} = $jack->{jackd_running}
		?  $config->{engine_base_jack_seek_delay} * ( 1 + $track_count / 20 )
		:  0;
	connect_jack_ports_list();
	transport_status() unless $quiet;
	something_to_run() or throw("Neither audio nor MIDI tracks active. Nothing to run."), return; 
	$ui->flash_ready();
	#print ecasound_iam("fs");
	1;
	
}
sub transport_status {
	
	map{ 
		pager(join '',"Warning: $_: input ",$tn{$_}->source,
		" is already used by track ",$setup->{inputs_used}->{$tn{$_}->source},".")
		if $setup->{tracks_with_duplicate_inputs}->{$_};
	} grep { $tn{$_}->rec } $bn{Main}->tracks;


	# assume transport is stopped
	# print looping status, setup length, current position
	my $start  = Audio::Nama::Mark::loop_start();
	my $end    = Audio::Nama::Mark::loop_end();
	#print "start: $start, end: $end, loop_enable: $mode->{loop_enable}\n";
	if (ref $setup->{record_midi} and %{$setup->{record_midi}}){
		pager(join(" ", keys %{$setup->{record_midi}}), ": ready for caching");
	}
	if ($mode->{loop_enable} and $start and $end){
		#if (! $end){  $end = $start; $start = 0}
		pager("looping from ", heuristic_time($start),
				 	"to ",   heuristic_time($end));
	}
	pagers("\nNow at: ", current_position());
	pagers("Engine is ". ( $this_engine->started() ? "running." : "ready."));
	pagers("\nPress SPACE to start or stop engine.")
		if $config->{press_space_to_start};
}

sub trigger_rec_setup_hooks {
	map { system($_->rec_setup_script) } 
	grep
	{ 
		logpkg(__FILE__,__LINE__,'trace',
			join "\n",
			"track ".$_->name,
			"rec status is: ".$_->rec_status,
			"old rec status: ".$setup->{_old_rec_status}->{$_->name},
			"script was ". (-e $_->rec_setup_script ) ? "found" : "not found"
		);
		$_->rec 
		and $setup->{_old_rec_status}->{$_->name} ne REC
		and -e $_->rec_setup_script
	} 
	rec_hookable_tracks();
}	
 sub trigger_rec_cleanup_hooks {
 	map { system($_->rec_cleanup_script) } 
	grep
	{ 	! $_->rec
		and $setup->{_old_rec_status}->{$_->name} eq REC
		and -e $_->rec_cleanup_script
	}
	rec_hookable_tracks();
}

1