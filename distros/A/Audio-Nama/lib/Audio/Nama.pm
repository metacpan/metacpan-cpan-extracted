package Audio::Nama;
require 5.10.0;
use vars qw($VERSION);
$VERSION = "1.208";
use Modern::Perl;
#use Carp::Always;
no warnings qw(uninitialized syntax);

########## External dependencies ##########

use Carp qw(carp cluck confess croak);
use Cwd;
use Data::Section::Simple qw(get_data_section);
use File::Find::Rule;
use File::Path;
use File::Spec;
use File::Spec::Link;
use File::Temp;
use Getopt::Long;
use Git::Repository;
use Graph;
use IO::Socket; 
use IO::Select;
use IPC::Open3;
use Log::Log4perl qw(get_logger :levels);
use Module::Load::Conditional qw(can_load); 
use Module::Load;
use Parse::RecDescent;
use Storable qw(thaw);
use Term::ReadLine;
use Text::Diff;
use Text::Format;
use Try::Tiny;
# use File::HomeDir;# Assign.pm
# use File::Slurp;  # several
# use List::Util;   # Fade.pm
# use List::MoreUtils; # Effects.pm
# use Time::HiRes; # automatically detected
# use Tk;           # loaded conditionally
# use Event;		# loaded conditionally
# use AnyEvent;		# loaded after Tk or Event
# use AnyEvent::Term::TermKey; # --ditto--
# use jacks;		# JACK server API
# use Protocol::OSC;

########## Nama modules ###########
#
# Note that :: in the *.p source files is expanded by       # SKIP_PREPROC
# preprocessing to Audio::Nama in the generated *.pm files. # SKIP_PREPROC
# ::Assign becomes Audio::Nama::Assign                      # SKIP_PREPROC
#
# These modules import functions and variables
#

use Audio::Nama::Assign qw(:all);
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Util qw(:all);

# Import the two user-interface classes

use Audio::Nama::Text;
use Audio::Nama::Graphical;

# They are descendents of a base class we define in the root namespace

our @ISA; # no ancestors
use Audio::Nama::Object qw(mode); # based on Object::Tiny

sub hello {"superclass hello"}

sub new { my $class = shift; return bless {@_}, $class }

# The singleton $ui belongs to either the Audio::Nama::Text or Audio::Nama::Graphical class
# depending on command line flags (-t or -g).
# This (along with the availability of Tk) 
# determines whether the GUI comes up. The Text UI
# is *always* available in the terminal that launched
# Nama.

# How is $ui->init_gui interpreted? If $ui belongs to class
# Audio::Nama::Text, Nama finds a no-op init_gui() stub in package Audio::Nama::Text
# and does nothing.

# If $ui belongs to class Audio::Nama::Graphical, Nama looks for
# init_gui() in package Audio::Nama::Graphical, finds nothing, so goes to
# look in the base class.  All graphical methods (found in
# Graphical_subs.pl) are defined in the root namespace so they can
# call Nama core methods without a package prefix.

######## Nama classes ########

use Audio::Nama::Track;
use Audio::Nama::Bus;    
use Audio::Nama::Sequence;
use Audio::Nama::Mark;
use Audio::Nama::IO;
use Audio::Nama::Wav;
use Audio::Nama::Insert;
use Audio::Nama::Fade;
use Audio::Nama::Edit;
use Audio::Nama::EffectChain;
use Audio::Nama::Lat;
use Audio::Nama::Engine;

####### Nama subroutines ######
#
# The following modules serve only to define and segregate subroutines. 
# They occupy the root namespace (except Audio::Nama::ChainSetup)
# and do not execute any code when use'd.

use Audio::Nama::AnalyseLV2;
use Audio::Nama::Initializations ();
use Audio::Nama::Options ();
use Audio::Nama::Config ();
use Audio::Nama::Custom ();
use Audio::Nama::Terminal ();
use Audio::Nama::Grammar ();
use Audio::Nama::Help ();

use Audio::Nama::Project ();
use Audio::Nama::Persistence ();
use Audio::Nama::Git;

use Audio::Nama::ChainSetup (); # separate namespace
use Audio::Nama::Graph ();
use Audio::Nama::Modes ();
use Audio::Nama::Mix ();
use Audio::Nama::Memoize ();

use Audio::Nama::EngineSetup ();
use Audio::Nama::EngineRun ();
use Audio::Nama::EngineCleanup ();
use Audio::Nama::EffectsRegistry ();
use Audio::Nama::Effect q(:all);
use Audio::Nama::MuteSoloFade ();
use Audio::Nama::Jack ();

use Audio::Nama::Regions ();
use Audio::Nama::CacheTrack ();
use Audio::Nama::Bunch ();
use Audio::Nama::Wavinfo ();
use Audio::Nama::Midi ();
use Audio::Nama::Latency ();
use Audio::Nama::Log qw(logit loggit logpkg logsub initialize_logger);

sub main { 
	say eval join(get_data_section('banner'), qw(" "));
	bootstrap_environment() ;
	load_project();
	process_command($config->{execute_on_project_load});
	reconfigure_engine();
	process_command($config->{opts}->{X});
	$ui->loop();
}

sub bootstrap_environment {
	definitions();
	process_command_line_options();
	start_logging();
	setup_grammar();
	setup_hotkey_grammar();
	initialize_interfaces();
}
sub cleanup_exit {
	logsub("&cleanup_exit");
 	remove_riff_header_stubs();
	trigger_rec_cleanup_hooks();
	# for each process: 
	# - SIGINT (1st time)
	# - allow time to close down
	# - SIGINT (2nd time)
	# - allow time to close down
	# - SIGKILL
	delete $project->{events};
	close_midish() if $config->{use_midish};
	my @engines = values %Audio::Nama::Engine::by_name;
	for (@engines){
		if( @{$_->{pids}}){
			map{ my $pid = $_; 
				 map{ my $signal = $_; 
					  kill $signal, $pid; 
					  sleeper(0.2);
					} (15,9);
				 waitpid $pid, 1;
			} @{$_->{pids}};
		}
	}
	$text->{term}->rl_deprep_terminal() if defined $text->{term};
	exit;
}
END { }

1;
__DATA__
@@ commands_yml
---
help:
  type: help 
  what: Display help on Nama commands.
  short: h
  parameters: [ <integer:help_topic_index> | <string:help_topic_name> | <string:command_name> ]
  example: |
    help marks # display the help category marks and all commands containing marks
    help 6 # display help on the effects category
    help mfx # display help on modify_effect - shortcut mfx
help_effect:
  type: help
  what: Display detailed help on LADSPA or LV2 effects.
  short: hfx he
  parameters: <string:label> | <integer:unique_id>
  example: |
    help_effect 1970 
    ! display help on Fons Adriaensen's parametric EQ (LADSPA)
    help_effect etd 
    ! prints a short message to consult Ecasound manpage, 
    ! where the etd chain operator is documented.
    hfx lv2-vocProc 
    ! display detailed help on the LV2 VocProc effect
find_effect:
  type: help
  what: Display one-line help for effects matching the search string(s).
  short: ffx fe
  parameters: <string:keyword1> [ <string:keyword2>... ]
  example: |
    find_effect compressor 
    ! List all effects containing "compressor" in their name or parameters
    fe feedback 
    ! List all effects matching "feedback" 
    ! (for example a delay with a feedback parameter)
exit:
  type: general
  what: Exit Nama, saving settings (the current project).
  short: quit q
  parameters: none
memoize:
  type: general
  what: |
    Enable WAV directory caching, so Nama won't have to scan
    the entire project folder for new files after every run.
    (default)
  parameters: none
unmemoize:
  type: general
  what: Disable WAV directory caching.
  parameters: none
stop:
  type: transport
  what: Stop transport. Stop the engine, when recording or playing back.
  short: s
  parameters: none
start:
  type: transport
  what: Start the transport rolling
  short: t
  parameters: none
  example: |
    rec   # prepare the curent track to be recorded.
    start # Start the engine/transport rolling (play now!)
    stop  # Stop the engine, cleanup, prepare to review
getpos:
  type: transport
  what: Get the current playhead position (in seconds).
  short: gp
  parameters: none
  example: |
    start # Start the engine.
    gp    # Get the current position of the playhead. Where am I?
setpos:
  type: transport
  what: Set current playhead position (in seconds).
  short: sp
  parameters: <float:position_seconds>
  example: setpos 65.5 # set current position to 65.5 seconds.
forward:
  type: transport
  what: Move playback position forwards (in seconds).
  short: fw
  parameters: <float:increment_seconds>
  example: fw 23.7 # forward 23.7 seconds from the current position.
rewind:
  type: transport
  what: Move playback position backwards (in seconds).
  short: rw
  parameters: <float:decrement_seconds>
  example: rewind 6.5 # Move backwards 6.5 seconds from the current position.
to_start:
  type: transport
  what: Set the playback head to the start. A synonym for setpos 0.
  short: beg
  parameters: none
to_end:
  type: transport
  what: Set the playback head to end minus 10 seconds.
  short: end
  parameters: none
ecasound_start:
  type: transport
  what: |
    Ecasound-only start. Nama will not monitor the transport.
    For diagnostic use.
  parameters: none
ecasound_stop:
  type: transport
  what: |
    Ecasound-only stop. Nama will not monitor the transport.
    For diagnostic use.
  parameters: none
restart_ecasound:
  type: transport
  what: |
    Restart the Ecasound process. May help if Ecasound has crashed 
    or is behaving oddly.
  parameters: none
preview:
  type: transport
  what: |
    Enter the preview mode. Configure Nama for playback and 
    passthru of live inputs without recording (for mic test, 
    rehearsal, etc.)
  short: song
  parameters: none
  example: |
    rec     # Set the current track to record from its source.
    preview # Enter the preview mode.
    start   # Playback begins. You can play live, adjust effects, 
    !       # forward, rewind, etc.
    stop    # Stop the engine/transport.
    arm     # Restore to normal recording/playback mode.
doodle:
  type: transport
  short: live
  what: |
    Enter doodle mode. Passthru of live inputs without
    recording. No playback. Intended for rehearsing and
    adjusting effects.
  parameters: none
  example: |
    doodle # Switch into doodle mode.
    start  # start the engine/transport running.
    (fool around)
    stop   # Stop the engine.
    arm    # Return to normal mode, allowing play and record to disk
mixdown:
  type: mix
  what: |
    Enter mixdown mode for subsequent engine runs. You will
    record a new mix each time you use the start command 
    until you leave the mixdown mode using "mixoff".
  short: mxd
  parameters: none
  example: |
    mixdown # Enter mixdown mode
    start   # Start the transport. The mix will be recorded by the
    !       # Mixdown track. The engine will run until the
    !       # longest track ends. (After mixdown Nama places 
    !       # a symlink to the WAV file and possibly ogg/mp3 
    !       # encoded versions in the project directory.)
    mixoff  # Return to the normal mode.
mixplay:
  type: mix
  what: |
    Enter Mixdown play mode, setting user tracks to OFF 
    and only playing the Mixdown track. Use "mixoff" to
    leave this mode.
  short: mxp
  parameters: none
  example: |
    mixplay # Enter the Mixdown play mode.
    start   # Play the Mixdown track.
    stop    # Stop playback.
    mixoff  # Return to normal mode.
mixoff:
  type: mix
  what: |
    Leave the mixdown or mixplay mode. Sets Mixdown track to OFF, 
    user tracks to MON.
  short: mxo
  parameters: none
automix:
  type: mix
  what: Normalize track volume levels and fix DC-offsets, then mixdown.
  parameters: none
master_on:
  type: mix
  what: |
    Turn on the mastering mode, adding tracks Eq, Low, Mid, High
    and Boost, if necessary. The mastering setup allows for one
    EQ and a three-band multiband compression and a final
    boosting stage. Using "master_off" to leave the mastering mode. 
  short: mr
  parameters: none
  example: |
    mr    # Turn on master mode.
    start # Start the playback.
    !     # Now you can adjust the Boost or global EQ.
    stop  # Stop the engine.
master_off:
  type: mix
  what: Leave mastering mode. The mastering network is disabled.
  short: mro
  parameters: none
add_track:
  type: track
  what: Create a new audio track.
  short: add new
  parameters: <string:name>
  example: |
    add_track clarinet 
    ! create a mono track called clarinet with input 
    ! from soundcard channel 1.
add_tracks:
  type: track
  what: Create one or more new tracks in one go.
  parameters: <string:name1> [ <string:name2>... ]
  example: add_tracks violin viola contra_bass
add_midi_track:
  type: track
  what: Create a new MIDI track.
  short: amt
  parameters: <string:name>
link_track:
  type: track
  what: Create a read-only track, that uses audio files from another track.
  short: link
  parameters: [<string:project_name>] <string:track_name> <string:link_name>
  example: |
    link my_song_part1 Mixdown part_1  
    ! Create a read-only track "part_1" in the current project
    ! using files from track "Mixdown" in project "my_song_part_1".
    !
    link_track compressed_piano piano
    ! Create a read-only track "compressed_piano" using files from
    ! track "piano". This is one way to provide wet and dry
    ! (processed and unprocessed) versions of same source.
    ! Another way would be to use inserts.
import_audio:
  type: track
  what: |
    Import a sound file (wav, ogg, mp3, etc.) to the
    current track, resampling it if necessary. The 
    imported file is set as current version.
  short: import
  parameters: <string:full_path_to_file> [ <integer:frequency> ]
  example: |
    import /home/samples/bells.flac 
    ! import the file bells.flac to the current track
    import /home/music/song.mp3 44100 
    ! import song.mp3, specifying the frequency
set_track:
  type: track
  what: Directly set current track parameters (use with care!).
  parameters: <string:track_field> <value>
record:
  type: track
  what: |
    Set the current track to record its source.  Creates the
    monitoring route if necessary. Recording to disk will begin
    on the next engine start. Use the "mon" or "off" commands to
    disable recording.
  short: rec
  parameters: none
  example: |
    rec
    ! Set the current track to record.
    start 
    ! A new version (take) will be written to disk, 
    ! creating a file such as sax_1.wav. Other tracks 
    ! may be recording or playing back as well.
    stop 
    ! Stop the recording/playback, automatically enter playback mode
play:
  type: track
  what: |
    Set the current track to playback the currently selected version. 
    Creates the monitoring route if necessary. The selected audio file 
    will play the next time the engine starts.
  parameters: none
mon:
  type: track
  what: |
    Create a monitoring route for the current track at
    the next opportunity.
  parameters: none
off:
  type: track
  what: |
    Remove the monitoring route for the current track and all
    track I/O at the next opportunity.  You can re-include it
    using "mon", "play" or "rec" commands.
  parameters: none
source:
  type: track
  what: |
    Set the current track's input (source), for example
    to a soundcard channel, or JACK client name
  short: src r
  parameters: |
    <integer:soundcard_channel> | <string:jack_client_name> 
    | <string:jack_port_name> <string:jack_ports_list> | 
    | <string:track_name> | <string:loop_id> | 'jack' | 'null' 
  example: |
    source 3 
    ! Take input from soundcard channel 3 (3/4 if track is stereo)
    !
    source null 
    ! Track's input is silence. This is useful for when an effect such 
    ! as a metronome or signal generator provides a source.
    ! 
    source LinuxSampler 
    ! Record input from the JACK client named LinuxSampler.
    ! 
    source synth:output_3 
    ! record from the JACK client synth, using the 
    ! port output_3 (see he jackd and jack_lsp manpages
    ! for more information).
    !
    source jack 
    ! This leaves the track input exposed as JACK ports
    ! such as Nama:sax_in_1 for manual connection.
    !
    source kit.ports
    ! The JACK ports listed in the file kit.ports (if it exists)
    ! will be connected to the track input.
    !
    ! Ports are listed pairwise in the .ports files for stereo tracks.
    ! This is convenient for use with the Hydrogen drumkit, 
    ! whose outputs use one JACK port per voice.
send:
  type: track
  what: Set an aux send for the current track. Remove sends with remove_send .
  short: aux
  parameters: <integer:soundcard_channel> | <string:jack_client_name> | <string:loop_id>
  example: |
    send 3 # Send the track output to soundcard channel 3.
    send jconvolver # Send the track output to the jconvolver JACK client.
remove_send:
  type: track
  what: Remove aux send from the current track.
  short: nosend noaux
  parameters: none
stereo:
  type: track
  what: Configure the current track to record two channels of audio
  parameters: none
mono:
  type: track
  what: Configure the current track to record one channel of audio
  parameters: none
set_version:
  type: track
  what: |
    Select a WAV file, by version number, for current track playback
    (Overrides a bus-level version setting)
  short: version ver
  parameters: <integer:version_number>
  example: |
    piano     # Select the piano track.
    version 2 # Select the second recorded version
    sh        # Display information about the current track
destroy_current_wav:
  type: track
  what: |
    Remove the currently selected recording version from the
    current track after confirming user intent. This DESTRUCTIVE
    command removes the underlying audio file from your disk.
    Use with caution.
  parameters: none
list_versions:
  type: track
  what: |
    List WAV versions of the current track. This will print the 
    numbers. 
  short: lver
  parameters: none
  example: |
    list_versions # May print something like: 1 2 5 7 9
    !             # The other versions might have been deleted earlier by you.
vol:
  type: track
  what: Change or show the current track's volume.
  short: v
  parameters: [ [ + | - | / | * ] <float:volume> ]
  example: |
    vol * 1.5 # Multiply the current volume by 1.5
    vol 75    # Set the current volume to 75
    !         # Depending on your namarc configuration, this means
    !         # either 75% of full volume (-ea) or 75 dB (-eadb).
    vol - 5.7 # Decrease current volume by 5.7 (percent or dB)
    vol       # Display the volume setting of the current track.
mute:
  type: track
  what: |
    Mute the current track by reducing the volume parameter.
    Use "unmute" to restore the former volume level.
  short: c cut
  parameters: none
unmute:
  type: track
  what: Restore previous volume level. It can be used after mute or solo.
  short: nomute C uncut
  parameters: none
unity:
  type: track
  what: Set the current track's volume to unity. This will change the volume to the default value (100% or 0 dB).
  parameters: none
  example: |
    vol 55 # Set volume to 55
    unity  # Set volume to the unity value.
    vol    # Display the current volume (should be 100 or 0, 
    !      # depending on your settings in namarc.)
solo:
  type: track
  what: |
    Mute all tracks but the current track or the tracks or 
    bunches specified. You can reverse this with nosolo.
  short: sl
  parameters: [ <strack_name_1> | <string:bunch_name_1> ] [ <string:track_name_2 | <string:bunch_name_2> ] ...
  example: |
    solo   # Mute all tracks but the current track.
    nosolo # Unmute all tracks, restoring prior state.
    solo piano bass Drums # Mute everything but piano, bass and Drums.
nosolo:
  type: track
  what: |
    Unmute all tracks which have been muted by a solo command.
    Tracks that had been muted before the solo command stay muted.
  short: nsl
  parameters: none
all:
  type: track
  what: |
    Unmute all tracks that are currently muted
  parameters: none
  example: |
    piano # Select track piano
    mute  # Mute the piano track.
    sax   # Select the track sax.
    solo  # Mute other tracks
    nosolo # Unmute other tracks (piano is still muted)
    all   # all tracks play
pan:
  type: track
  what: |
    Change or display the current panning position of the 
    current track. Panning is moving the audio in the stereo 
    panorama between right and left. Position is given in percent. 
    0 is hard left and 100 hard right, 50% is dead centre.
  short: p
  parameters: [ <float:pan_position_in_percent> ]
  example: |
    pan 75 # Pan the track to a position between centre and hard right
    p 50   # Move the current track to the centre.
    pan    # Show the current position of the track in the stereo panorama.
pan_right:
  type: track
  what: |
    Pan the current track hard right. this is a synonym for pan 100. 
    Can be reversed with pan_back.
  short: pr
  parameters: none
pan_left:
  type: track
  what: |
    Pan the current track hard left. This is a synonym for pan 0. 
    Can be reversed with pan_back.
  short: pl
  parameters: none
pan_center:
  type: track
  what: |
    Pan the current track to the centre. This is a synonym for pan 50.
    Can be reversed with pan_back.
  short: pc
  parameters: none
pan_back:
  type: track
  what: |
    Restore the current track's pan position prior to pan_left, 
    pan_right or pan_center commands.
  short: pb
  parameters: none
show_tracks:
  type: track 
  what: |
    Show a list of tracks, including their index number, volume, 
    pan position, recording status and source.
  short: lt show
  parameters: none
show_tracks_all:
  type: track
  what: Like show_tracks, but includes hidden tracks as well. Useful for debugging.
  short: sha showa
  parameters: none
show_bus_tracks:
  type: track 
  what: Show a list of tracks in the current bus.
  short: ltb showb
  parameters: none
show_track:
  type: track
  what: |
    Display full information about the current track: index, recording 
    status, effects and controllers, inserts, the selected
    WAV version, and signal width (channel count).
  short: sh -fart
  parameters: none
show_mode:
  type: setup
  what: |
    Display the current record/playback mode. this will indicate the 
    mode (doodle, preview, etc.) and possible record/playback settings.
  short: shm
  parameters: none
show_track_latency:
  type: track
  what: display the latency information for the current track.
  short: shl
  parameters: none
show_latency_all:
  type: diagnostics
  what: Dump all latency data.
  short: shla
  parameters: none
set_region:
  type: track
  what: |
    Specify a playback region for the current track using marks. 
    Can be reversed with remove_region.
  short: srg
  parameters: <string:start_mark_name> <string:end_mark_name>
  example: |
    sax            # Select "sax" as the current track.
    setpos 2.5     # Move the playhead to 2.5 seconds.
    mark sax_start # Create a mark
    sp 120.5       # Move playhead to 120.5 seconds.
    mark sax_end   # Create another mark
    set_region sax_start sax_end 
    !  Play only the audio from 2.5 to 120.5 seconds.
add_region:
  type: track
  what: |
    Make a copy of the current track using the supplied a region 
    definition. The original track is untouched.
  parameters: <string:start_mark_name> | <float:start_time> <string:end_mark_name> | <float:end_time> [ <string:region_name> ]
  example: |
    sax # Select "sax" as the current track.
    add_region sax_start 66.7 trimmed_sax 
    ! Create "trimmed_sax", a copy of "sax" with a region defined
    ! from mark "sax_start" to 66.7 seconds. 
remove_region:
  type: track
  what: |
    Remove the region definition from the current track.
    Remove the current track if it is an auxiliary track.
  short: rrg
  parameters: none
shift_track:
  type: track
  what: |
    Choose an initial delay before playing a track or region.
    Can be reversed by unshift_track.
  short: shift playat pat
  parameters: <string:start_mark_name> | <integer:start_mark_index | <float:start_seconds>
  example: |
    piano     # Select "piano" as current track.
    shift 6.7 # Move the start of track to 6.7 seconds.
unshift_track:
  type: track
  what: Restore the playback start time of a track or region to 0. 
  short: unshift
  parameters: none
modifiers:
  type: track
  what: |
    Add/show modifiers for the current track (man ecasound for details). 
    This provides direct control over Ecasound track modifiers   
    It is not needed for normal work.
  short: mods mod
  parameters: [ Audio file sequencing parameters ]
  example: |
    modifiers select 5 15.2 
    ! Apply Ecasound's select modifier to the current track.
    ! The usual way to accomplish this is with a region definition. 
nomodifiers:
  type: track
  what: Remove modifiers from the current track.
  short: nomods nomod
  parameters: none
normalize:
  type: track
  what: |
    Apply ecanormalize to the current track version. This will
    raise the gain/volume of the current track as far as
    possible without clipping and store it that way on disk. 
    Note: this will permanently change the file.
  short: ecanormalize
  parameters: none
fixdc:
  type: track
  what: |
    Fix the DC-offset of the current track using ecafixdc. 
    Note: This will permanently change the file.
  short: ecafixdc
  parameters: none
autofix_tracks:
  type: track 
  what: Apply ecafixdc and ecanormalize to all current versions of all tracks, set to playback (MON).
  short: autofix
  parameters: none
remove_track:
  type: track
  what: |
    Remove the current track with its effects, inserts, etc.
    Audio files are unchanged. 
  parameters: none
bus_mon:
  type: bus
  what: Set the current bus mix_track to monitor (the default behaviour).
  short: bmon
  parameters: none
bus_off:
  type: bus
  what: |
    Set current bus mixtrack to OFF. Can be reversed
    with bus_rec or bus_mon.
  short: boff
  parameters: none
bus_version:
  type: group
  what: Set the default monitoring version for tracks in the current bus.
  short: bver gver
  parameters: none
add_bunch:
  type: group
  what: 
  short: abn
  parameters: <string:bunch_name> [ <string:track_name_1> | <integer:track_index_1> ] ...
  example: |
    add_bunch strings violin cello bass
    ! Create a bunch "strings" with tracks violin, cello and bass.
    for strings; mute # Mute all tracks in the strings bunch.
    for strings; vol * 0.8 
    ! Lower the volume of all tracks in bunch "strings" by a
    ! a factor of 0.8.
list_bunches:
  type: group
  what: Display a list of all bunches and their tracks.
  short: lbn
  parameters: none
remove_bunch:
  type: group
  what: |
    Remove the specified bunches. This does not remove 
    the tracks, only the grouping.
  short: rbn
  parameters: <string:bunch_name> [ <string:bunch_name> ] ...
add_to_bunch:
  type: group
  what: Add track(s) to an existing bunch.
  short: atbn
  parameters: <string:bunch_name> <string:track1> [ <string:track2> ] ...
  example: |
    add_to_bunch woodwind oboe sax flute 
commit:
  type: project
  what: commit Nama's current state
  short: ci
  parameters: <string:message>
tag:
  type: project
  what: git tag the current branch HEAD commit
  parameters: <string:tag_name> [<string:message>]
branch:
  type: project
  what: change to named branch
  short: br
  parameters: <string:branch_name>
list_branches:
  type: project
  what: list branches
  short: lb lbr
new_branch:
  type: project
  what: create a new branch
  short: nbr
  parameters: <string:new_branch_name> [<string:existing_branch_name>]
save_state:
  type: project
  what: Save the project settings as file or git snapshot
  short: keep save
  parameters: [ <string:settings_target> [ <string:message> ] ]
get_state:
  type: project
  what: Retrieve project settings from file or snapshot
  short: get recall retrieve
  parameters: <string:settings_target>
list_projects:
  type: project
  what: List all projects. This will list all Nama projects, which are stored in the Nama project root directory.
  short: lp
  parameters: none
new_project:
  type: project
  what: Create or open a new empty Nama project.
  short: create
  parameters: <string:new_project_name>
  example: |
    create jam 
    # creates empty project call "jam".
    # Now you can start adding your tracks, editing them and mixing them.
load_project:
  type: project
  what: Load an existing project. This will load the project from the default project state file. If you wish to load a project state saved to a user specific file, load the project and then use get_state.
  short: load
  parameters: <string:existing_project_name>
  example: load my_old_song # Will load my_old_song just as you left it.
project_name:
  type: project
  what: Display the name of the current project.
  short: project name
  parameters: none
new_project_template:
  type: project
  what: Make a project template based on the current project. This will include tracks and busses.
  short: npt
  parameters: <string:template_name> [ <string:template_description> ]
  example: |
    new_project_template my_band_setup "tracks and busses for bass, drums and me"
use_project_template:
  type: project
  what: Use a template to create tracks in a newly created, empty project.
  short: upt apt
  parameters: <string:template_name>
  example: |
    apt my_band_setup # Will add all the tracks for your basic band setup.
list_project_templates:
  type: project
  what: List all project templates.
  short: lpt
  parameters: none
destroy_project_template:
  type: project
  what: Remove one or more project templates.
  parameters: <string:template_name1> [ <string:template_name2> ] ...
generate:
  type: setup
  what: Generate an Ecasound chain setup for audio processing manually. Mainly useful for diagnostics and debugging.
  short: gen
  parameters: none
arm:
  type: setup
  what: Generate and connect a setup to record or playback. If you are in dodle or preview mode, this will bring you back to normal mode.
  parameters: none
arm_start:
  type: setup
  what: Generate and connect the setup and then start. This means, that you can directly record or listen to your tracks.
  short: arms
  parameters: none
connect:
  type: setup
  what: Connect the setup, so everything is ready to run. Ifusing JACK, this means, that Nama will connect to all the necessary JACK ports.
  short: con
  parameters: none
disconnect:
  type: setup
  what: Disconnect the setup. If running with JACK, this will disconnect from all JACK ports.
  short: dcon
  parameters: none
show_chain_setup:
  type: setup
  what: Show the underlying Ecasound chain setup for the current working condition. Mainly useful for diagnostics and debugging.
  short: chains
  parameters: none
loop:
  type: setup
  what: Loop the playback between two points. Can be stopped with loop_disable
  short: l
  parameters: <string:start_mark_name> | <integer:start_mark_index> | <float:start_time_in_secs> <string:end_mark_name> | <integer:end_mark_index> | <float:end_time_in_secs>
  example: |
    loop 1.5 10.0 # Loop between 1.5 and 10.0 seconds.
    loop 1 5 # Loop between marks with indeices 1 and 5, see list_marks.
    loop sax_start 12.6 # Loop between mark sax_start and 12.6 seconds.
noloop:
  type: setup
  what: Disable looping.
  short: nl
  parameters: none
add_controller:
  type: effect
  what: Add a controller to an effect (current effect, by default). Controllers can be modified by using mfx and removed using rfx.
  short: acl
  parameters: [ <string:operator_id> ] <string:effect_code> [ <float:param1> <float:param2> ] ...
  example: |
    add_effect etd 100 2 2 50 50 # Add a stero delay of 100ms.
    ! the delay will get the effect ID E .
    ! Now we want to slowly change the delay to 200ms.
    acl E klg 1 100 200 2 0 100 15 200 # Change the delay time linearly (klg)
        # from 100ms at the start (0 seconds) to 200ms at 15 seconds. See
        # help for -klg in the Ecasound manpage.
add_effect:
  type: effect
  what: Add an effect 
  short: afx
  parameters: |
    [ (before <fx_alias> | first | last ) ] <fx_alias> [ <float:param1> <float:param2>... ]
    "before", "first" and "last" can be abbreviated "b", "f" and "l", respectively.
  example: |
    We want to add the decimator effect (a LADSPA plugin).
    help_effect decimator # Print help about its paramters/controls.
    !                     # We see two input controls: bitrate and samplerate
    afx decimator 12 22050  #  prints "Added GO (Decimator)"
    ! We have added the decimator with 12bits and a sample rate of 22050Hz.
    ! GO is the effect ID, which you will need to modify it.
add_effect_last:
  type: effect
  what: same as add-effect last
  short: afxl
  parameters: <fx_alias> [ <float:param1> <float:param2>... ]
add_effect_first:
  type: effect
  what: same as add-effect first
  short: afxf
  parameters: <fx_alias> [ <float:param1> <float:param2>... ]
add_effect_before:
  type: effect
  what: same as add-effect before
  short: afxb
  parameters: <fx_alias> <fx_alias> [ <float:param1> <float:param2>... ]
modify_effect:
  type: effect
  what: Modify effect parameter(s).
  short: mfx
  parameters: |
    [ <fx_alias> ] <integer:parameter> [ + | - | * | / ] <float:value>
    fx_alias can be: a position, effect ID, nickname or effect code
  example: |
    To change the roomsize of our reverb effect to 62
    lfx 
    ! We see that reverb has unique effect ID AF and roomsize is the
    ! first parameter.
    mfx AF 1 62 
    ! 
    mfx AF,BG 1 75 
    ! Change the first parameter of both AF and BG to 75.
    !
    mfx CE 6,10 -3 
    ! Change parameters 6 and 10 of effect CE to -3
    !
    mfx D 4 + 10 
    ! Increase the fourth parameter of effect D by 10.
    ! 
    mfx A,B,C 3,6 * 5 
    ! Adjust parameters 3 and 6 of effect A, B and C by a factor of 5.
remove_effect:
  type: effect
  what: Remove effects. They don't have to be on the current track.
  short: rfx
  parameters: <fx_alias1> [ <fx_alias2> ] ...
position_effect:
  type: effect
  what: Position an effect before another effect (use 'ZZZ' for end).
  short: pfx
  parameters: <string:id_to_move> <string:position_id>
  example: |
    position_effect G F # Move effecit with unique ID G before F.
show_effect:
  type: effect
  what: Show information about an effect. Default is to print information on the current effect.
  short: sfx
  parameters: [ <string:effect_id1> ] [ <string:effect_id2> ] ...
  example: |
    sfx # Print name, unique ID and parameters/controls of the current effect.
    sfx H # Print out all information about effect with unique ID H.
dump_effect:
  type: effect
  what: Dump all data of current effect object
  short: dfx
list_effects:
  type: effect
  what: Print a short list of all effects on the current track, only including unique ID and effect name.
  short: lfx
  parameters: none
hotkeys:
  type: general
  what: |
    Use this command to set the hotkey mode. (You may also use the hash symbol '#'.)
    Hit the Escape key to return to command mode.
  short: hk 
  parameters: none
hotkeys_always:
  type: general 
  what: Activate hotkeys mode after each command.
  short: hka 
  parameters: none
hotkeys_off:
  type: general
  what: disable hotkeys always mode
  short: hko
  parameters: none
hotkeys_list:
  type: general
  what: list hotkey bindings
  short: hkl lhk
  parameters: none
add_insert:
  type: effect 
  what: Add an external send/return insert to current track.
  short: ain
  parameters: |
      External: ( pre | post ) <string:send_id> [ <string:return_id> ]
      Local wet/dry: local
  example: |
    add_insert pre jconvolver 
    ! Add a prefader insert. The current track signal is sent 
    ! to jconvolver and returned to the vol/pan controls.
    add_insert post jconvolver csound 
    ! Send the current track postfader signal (after vol/pan
    ! controls) to jconvolver, getting the return from csound.
    guitar # Select the guitar track
    ain local # Create a local insert
    guitar-1-wet # Select the wet arm 
    afx G2reverb 50 5.0 0.6 0.5 0 -16 -20 # add a reverb
    afx etc 6 100 45 2.5 # add a chorus effect on the reverbed signal
    guitar # Change back to the main guitar track
    wet 25 # Set the balance between wet/dry track to 25% wet, 75% dry.
set_insert_wetness:
  type: effect 
  what: Set wet/dry balance of the insert for the current track. The balance is given in percent, 0 meaning dry and 100 wet signal only.
  short: wet
  parameters: [ pre | post ] <n_wetness>
  example: |
    wet pre 50 # Set the prefader insert to be balanced 50/50 wet/dry.
    wet 100 # Simpler if there's only one insert
remove_insert:
  type: effect
  what: Remove an insert from the current track.
  short: rin
  parameters: [ pre | post ]
  example: |
    rin # If there is only one insert on the current track, remove it.
    remove_insert post # Remove the postfader insert from the current track.
ctrl_register:
  type: effect
  what: List all Ecasound controllers. Controllers include linear controllers and oscillators.
  short: crg
  parameters: none
preset_register:
  type: effect
  what: List all Ecasound effect presets. See the Ecasound manpage for more detail on effect_presets.
  short: prg
  parameters: none
ladspa_register:
  type: effect
  what: List all LADSPA plugins, that Ecasound/Nama can find.
  short: lrg
  parameters: none
list_marks:
  type: mark
  what: List all marks with index, name and their respective positions in time.
  short: lmk lm
  parameters: none
to_mark:
  type: mark
  what: Move the playhead to the named mark or mark index.
  short: tmk tom
  parameters: <string:mark_name> | <integer:mark_index>
  example: |
    to_mark sax_start # Jump to the position marked by sax_mark.
    tmk 2 # Move to the mark with the index 2.
add_mark:
  type: mark
  what: Drop a new mark at the current playback position. this will fail, if a mark is already placed on that exact position.
  short: mark amk k
  parameters: [ <string:mark_id> ]
  example: |
    mark start # Create a mark named "start" at the current position.
remove_mark:
  type: mark
  what: Remove a mark
  short: rmk
  parameters: [ <string:mark_name> | <integer:mark_index> ]
  example: |
    remove_mark start # remove the mark named start
    rmk 16 # Remove the mark with the index 16.
    rmk    # Remove the current mark
next_mark:
  type: mark
  what: Move the playhead to the next mark.
  short: nmk
  parameters: none
previous_mark:
  type: mark
  what: Move the playhead to the previous mark.
  short: pmk
  parameters: none
name_mark:
  type: mark
  what: Give a name to the current mark.
  parameters: <string:mark_name>
modify_mark:
  type: mark
  what: Change the position (time) of the current mark.
  short: move_mark mmk
  parameters: [ + | - ] <float:seconds>
  example: |
    move_mark + 2.3 # Move the current mark 2.3 seconds forward from its
                    # current position.
    mmk 16.8 # Move the current mark to 16.8 seconds, no matter, where it is now.
engine_status:
  type: diagnostics
  what: Display the Ecasound audio processing engine status.
  short: egs
  parameters: none
dump_track:
  type: diagnostics
  what: Dump current track data.
  short: dump
  parameters: none
dump_group:
  type: diagnostics 
  what: Dump group settings for user tracks.
  short: dumpg
  parameters: none
dump_all:
  type: diagnostics
  what: Dump most internal state data.
  short: dumpa
  parameters: none
dump_io:
  type: diagnostics
  what: Show chain inputs and outputs.
  parameters: none
list_history:
  type: help
  what: List the command history. Every project stores its own command history.
  short: lh
  parameters: none
add_submix_cooked:
  type: bus
  what: Create a submix using all tracks in bus "Main"
  short: 
  parameters: <string:name> <destination>
  example: |
    add_submix_cooked front_of_house 7
    ! send a custom mix named "front_of_house"
    ! to soundcard channels 7/8
add_submix_raw:
  type: bus
  what: Add a submix using tracks in Main bus (unprocessed signals, lower latency)
  short: asr
  parameters: <string:name> <destination>
  example: |
    asbr Reverb jconv # Add a raw send bus called Reverb, with its output
                      # going to the JACK client jconv .
add_bus:
  type: bus
  what: Add a sub bus. This is a bus, as known from other DAWs. The default output goes to a mix track and that is routed to the mixer (the Master track). All busses begin with a capital letter!
  short: abs
  parameters: <string:name> [ <string:track_name> | <string:jack_client> | <integer:soundcard_channel> ]
  example: |
    abs Brass          # Add a bus, "Brass", routed to the Main bus (e.g. mixer)
    abs special csound # Add a bus, "special" routed to JACK client "csound"
update_submix:
  type: bus
  what: Include tracks added since the submix was created.
  short: usm
  parameters: <string:name>
  example: update_submix Reverb # Include new tracks in the Reverb submix
remove_bus:
  type: bus
  what: Remove a bus or submix
  parameters: <string:bus_name>
list_buses:
  type: bus
  what: List buses and their parameters (TODO).
  short: lbs
  parameters: none
set_bus:
  type: bus
  what: Set bus parameters. This command is intended for advanced users.
  short: sbs
  parameters: <string:busname> <key> <value>
overwrite_effect_chain:
  type: effect
  what: |
    Create a new effect chain, overwriting an existing one
    of the same name.
  short: oec
  parameters: Same as for new_effect_chain
new_effect_chain:
  type: effect
  what: | 
    Create an effect chain, a named list of effects with all 
    parameter settings. Useful for storing effect setups
    for particular instruments.
  short: nec
  parameters: <string:name> [ <effect_id_1> <effect_id_2>... ] 
  example: |
    new_effect_chain my_piano 
    ! Create a new effect chain, "my_piano", storing all 
    ! effects and their settings from the current track
    ! except the fader (vol/pan) settings.
    nec my_guitar A C F G H 
    ! Create a new effect chain, "my_guitar",
    ! storing the effects with IDs A, C, F, G, H and
    ! their respective settings.
delete_effect_chain:
  type: effect
  what: |
    Delete an effect chain definition. Does not affect the
    project state. This command is not reversible by undo.
  short: dec destroy_effect_chain 
  parameters: <string:effect_chain_name>
find_effect_chains:
  type: effect
  what: Dump effect chains, matching key/value pairs if provided
  short: fec
  parameters: [ <string:key_1> <string:value_1> ] ...
  example: |
    fec # List all effect chains with their effects.
find_user_effect_chains:
  type: effect
  what: List all *user* created effect chains, matching key/value pairs, if provided.
  short: fuec
  parameters: [ <string:key_1> <string:value_1> ] ...
bypass_effects:
  type: effect
  what: Bypass effects on the current track. With no parameters default to bypassing the current effect.
  short: bypass bfx
  parameters: [ <string:effect_id_1> <string:effect_id_2>... | 'all' ]
  example: |
    bypass all # Bypass all effects on the current track, except vol and pan.
    bypass AF  # Only bypass the effect with the unique ID AF.
bring_back_effects:
  type: effect
  what: Restore effects. If no parameter is given, the default is to restore the current effect.
  short: restore_effects bbfx
  parameters: [ <string:effect_id_1> <string:effect_id_2> ... | 'all' ]
  example: |
    bbfx                   # Restore the current effect.
    restore_effect AF      # Restore the effect with the unique ID AF.
    bring_back_effects all # Restore all effects.
new_effect_profile:
  type: effect
  what: Create a new effect profile. An effect profile is a named group of effect chains for multiple tracks. Useful for storing a basic template of standard effects for a group of instruments, like a drum kit.
  short: nep
  parameters: <string:bunch_name> [ <string:effect_profile_name> ]
  example: |
    add_bunch Drums snare toms kick # Create a buch called Drums.
    nep Drums my_drum_effects # Create an effect profile, call my_drum_effects
                              # containing all effects from snare toms and kick.
apply_effect_profile:
  type: effect
  what: Apply an effect profile. this will add all the effects in it to the list of tracks stored in the effect profile. Note: You must give the tracks the same names as in the original project, where you created the effect profile.
  short: aep
  parameters: <string:effect_profile_name>
destroy_effect_profile:
  type: effect
  what: Delete an effect profile. This will delete the effect profile definition from your disk. All projects, which use this effect profile will NOT be affected.
  parameters: <string:effect_profile_name>
list_effect_profiles:
  type: effect
  what: List all effect profiles.
  short: lep
  parameters: none
show_effect_profiles:
  type: effect
  what: List effect profile.
  short: sepr
  parameters: none
full_effect_profiles:
  type: effect
  what: Dump effect profile data structure.
  short: fep
  parameters: none
cache_track:
  type: track
  what: |
    Cache the current track. Same as freezing or bouncing. This
    is useful for larger projects or low-power CPUs, since
    effects do not have to be recomputed for subsequent engine
    runs.
    
    Cache_track stores the effects-processed output of the
    current track as a new version (WAV file) which becomes the
    current version.  The current effects, inserts and region
    definition are removed and stored. 

    To go back to the original track state, use the
    uncache_track command.  The show_track display appends a "c"
    to version numbers created by cache_track (and therefore
    reversible by uncache) 
    
  short: cache ct bounce freeze
  parameters: [ <float:additional_processing_time> ]
  example: |
      cache 10 # Cache the curent track and append 10 seconds extra time,
               # to allow a reverb or delay to fade away without being cut.
uncache_track:
  type: effect
  what: Select the uncached track version. This restores effects, but not inserts.
  short: uncache unc
  parameters: none
do_script:
  type: general
  what: Execute Nama commands from a file in the main project's directory or in the Nama project root directory. A script is a list of Nama commands, just as you would type them on the Nama prompt.
  short: do
  parameters: <string:filename>
  example: |
    do prepare_my_drums # Execute the script prepare_my_drums.
scan:
  type: general
  what: Re-read the project's .wav directory. Mainly useful for troubleshooting.
  parameters: none
add_fade:
  type: effect
  what: Add a fade-in or fade-out to the current track.
  short: afd fade
  parameters: ( in | out ) marks/times (see examples)
  example: |
    fade in mark1       # Fade in,starting at mark1 and using the 
    !                    # default fade time of 0.5 seconds.
    fade out mark2 2    # Fade out over 2 seconds, starting at mark2 .
    fade out 2 mark2    # Fade out over 2 seconds, ending at mark2 .
    fade in mark1 mark2 # Fade in starting at mark1, ending at mark2 .
remove_fade:
  type: effect 
  what: Remove a fade from the current track.
  short: rfd
  parameters: <integer:fade_index_1> [ <integer:fade_index_2> ] ...
  example: |
    list_fade # Print a list of all fades and their tracks.
    rfd 2     # Remove the fade with the index (n) 2.
list_fade:
  type: effect
  what: List all fades.
  short: lfd
  parameters: none
add_comment:
  type: track
  what: Add a comment to the current track (replacing any previous comment). A comment maybe a short discription, notes on instrument settings, etc.
  short: comment ac
  parameters: <string:comment>
  example: ac "Guitar, treble on 50%"
remove_comment:
  type: track
  what: Remove a comment from the current track.
  short: rc
  parameters: none
show_comment:
  type: track
  what: Show the comment for the current track.
  short: sc
  parameters: none
show_comments:
  type: track
  what: Show all track comments.
  short: sca
  parameters: none
add_version_comment:
  type: track
  what: Add a version comment (replacing any previous user comment). This will add a comment for the current version of the current track.
  short: avc
  parameters: <string:comment>
  example: avc "The good take with the clear 6/8"
remove_version_comment:
  type: track
  what: Remove version comment(s) from the current track.
  short: rvc
  parameters: none
show_version_comment:
  type: track
  what: Show version comment(s) of the curent track.
  short: svc
  parameters: none
show_version_comments_all:
  type: track
  what: Show all version comments for the current track.
  short: svca
  parameters: none
set_system_version_comment:
  type: track
  what: Set a system version comment. Useful for testing and diagnostics.
  short: ssvc
  parameters: <string:comment>
midish_command:
  type: midi
  what: Send the command text to the midish MIDI sequencer. Midish must be installed and enabled in namarc. See the midish manpage and fullonline documentation for more.
  short: m
  parameters: <string:command_text>
  example: m tracknew my_midi_track # create a new MIDI track in midish.
midish_mode_on:
  type: midi
  what: all users commands sent to midish, until
  short: mmo
midish_mode_off:
  what: exit midish mode, restore default Nama command mode, no midish sync
  type: midi
  short: mmx
midish_mode_off_ready_to_play:
  what: exit midish mode, sync midish start (p) with Ecasound
  type: midi
  short: mmxrp
midish_mode_off_ready_to_record:
  what: exit midish mode, sync midish start (r) with Ecasound
  type: midi
  short: mmxrr
new_edit:
  type: edit
  what: Create an edit for the current track and version.
  short: ned
  parameters: none
set_edit_points:
  type: edit
  what: Mark play-start, record-start and record-end positions for the current edit.
  short: sep
  parameters: none
list_edits:
  type: edit
  what: List all edits for current track and version.
  short: led
  parameters: none
select_edit:
  type: edit
  what: Select an edit to modify or delete. After selection it is the current edit.
  short: sed
  parameters: <integer:edit_index>
end_edit_mode:
  type: edit
  what: Switch back to normal playback/record mode. The track will play full length again. Edits are managed via a sub- bus.
  short: eem
  parameters: none
destroy_edit:
  type: edit
  what: Remove an edit and all associated audio files. If no parameter is given, the default is to destroy the current edit. Note: The data will be lost permanently. Use with care!
  parameters: [ <integer:edit_index> ]
preview_edit_in:
  type: edit
  what: Play the track region without the edit segment.
  short: pei
  parameters: none
preview_edit_out:
  type: edit
  what: Play the removed edit segment.
  short: peo
  parameters: none
play_edit:
  type: edit
  what: Play a completed edit.
  short: ped
  parameters: none
record_edit:
  type: edit
  what: Record an audio file for the current edit.
  short: red
  parameters: none
edit_track:
  type: edit
  what: set the edit track as the current track.
  short: et
  parameters: none
host_track_alias:
  type: edit
  what: Set the host track alias as the current track.
  short: hta
  parameters: none
host_track:
  type: edit
  what: Set the host track (edit sub-bus mix track) as the current track.
  short: ht
  parameters: none
version_mix_track:
  type: edit
  what: Set the version mix track as the current track.
  short: vmt
  parameters: none
play_start_mark:
  type: edit
  what: Select (and move to) play start mark of the current edit.
  short: psm
  parameters: none
rec_start_mark:
  type: edit
  what: Select (and move to) rec start mark of the current edit.
  short: rsm
  parameters: none
rec_end_mark:
  type: edit
  what: Select (and move to) rec end mark of the current edit.
  short: rem
  parameters: none
set_play_start_mark:
  type: edit
  what: Set play_start_mark to the current playback position.
  short: spsm
  parameters: none
set_rec_start_mark:
  type: edit
  what: Set rec_start_mark to the current playback position.
  short: srsm
  parameters: none
set_rec_end_mark:
  type: edit
  what: Set rec_end_mark to current playback position.
  short: srem
  parameters: none
disable_edits:
  type: edit
  what: Turn off the edits for the current track and playback the original. This will exclude the edit sub bus.
  short: ded
  parameters: none
merge_edits:
  type: edit
  what: Mix edits and original into a new host-track. this will write a new audio file to disk and the host track will have a new version for this.
  short: med
  parameters: none
explode_track:
  type: track
  what: Make the current track into a sub bus, with one track for each version.
  parameters: none
move_to_bus:
  type: track
  what: Move the current track to another bus. A new track is always in the Main bus. So to reverse this action use move_to_bus Main .
  short: mtb
  parameters: <string:bus_name>
  example: |
    asub Drums # Create a new sub bus, called Drums.
    snare # Make snare the current track.
    mtb Drums # Move the snare track into the sub bus Drums.
promote_version_to_track:
  type: track
  what: Create a read-only track using the specified version of the current track.
  short: pvt
  parameters: <integer:version_number>
read_user_customizations:
  type: general
  what: Re-read the user customizations file 'custom.pl'.
  short: ruc
  parameters: none
limit_run_time:
  type: setup
  what: Stop recording after the last audio file finishes playing. Can be turned off with limit_run_time_off.
  short: lr
  parameters: [ <float:additional_seconds> ]
limit_run_time_off:
  type: setup
  what: Disable the recording stop timer.
  short: lro
  parameters: none
offset_run:
  type: setup
  what: Record/play from a mark, rather than from the start, i.e. 0.0 seconds.
  short: ofr
  parameters: <string:mark_name>
offset_run_off:
  type: setup
  what: Turn back to starting from 0.
  short: ofro
  parameters: none
view_waveform:
  type: general
  what: Launch mhwavedit to view/edit waveform of the current track and version. This requires to start Nama on a graphical terminal, like xterm or gterm or from GNOME via alt+F2 .
  short: wview
  parameters: none
edit_waveform:
  type: general
  what: Launch audacity to view/edit the waveform of the current track and version. This requires starting Nama on a graphical terminal like xterm or gterm or from GNOME starting Nama using alt+F2 .
  short: wedit
  parameters: none
rerecord:
  type: setup
  what: Record as before. This will set all the tracks to record, which have been recorded just before you listened back.
  short: rerec
  parameters: none
  example: |
    for piano guitar;rec # Set piano and guitar track to record.
    ! do your recording and ilstening.
    ! You want to record another version of both piano and guitar:
    rerec # Sets piano and guitar to record again.
analyze_level:
  type: track
  what: Print Ecasound amplitude analysis for current track. This will show highest volume and statistics.
  short: anl
  parameters: none
for:
  type: general
  what: Execute command(s) for several tracks.
  parameters: <string:track_name_1> [ <string:track_name_2>} ... ; <string:commands>
  example: |
    for piano guitar; vol - 3; pan 75      # reduce volume and pan right
    for snare kick toms cymbals; mtb Drums # move tracks to bus Drums
git:
  type: project
  what: execute git command in the project directory
  parameters: <string:command_name> [arguments]
edit_rec_setup_hook:
  type: track
  what: edit the REC hook script for current track
  short: ersh
  parameters: none
edit_rec_cleanup_hook:
  type: track
  what: edit the REC cleanup hook script for current track
  short: erch
  parameters: none
remove_fader_effect:
  type: track
  short: rffx
  what: remove vol pan or fader on current track
  parameters: vol | pan | fader
rename_track:
  type: track
  what: rename a track and its WAV files
  parameters: <string:old_track> <string:new_track>
new_sequence:
  type: sequence
  short: nsq
  what: define a new sequence
  parameters: <string:name> <track1, track2,...>
select_sequence:
  type: sequence
  short: slsq
  what: select named sequence as current sequence
  parameter: <string:name>
list_sequences:
  type: sequence
  short: lsq
  what: list all user sequences
show_sequence:
  type: sequence
  short: ssq
  what: display clips making up current sequence
  parameters: none
append_to_sequence:
  type: sequence
  short: asq
  what: append items to sequence
  parameters: [<string:name1>,...]
  example: |
    asq chorus # append chorus track to current sequence
    asq        # append current track to current sequence
insert_in_sequence:
  type: sequence
  short: isq
  what: insert items into sequence before index i
  parameters: <string:name1> [<string:name2>,...] <integer:index>
remove_from_sequence:
  type: sequence
  short: rsq
  what: remove items from sequence
  parameters: <integer:index1> [<integer:index2>,...]
delete_sequence:
  type: sequence
  short: dsq
  what: delete entire sequence
  parameters: <string:sequence>
add_spacer:
  type: sequence
  short: asp
  what: add a spacer to the current sequence, in specified position, or appending (if no position is given)
  parameters: <float:duration> [<integer:position>]
convert_to_sequence:
  type: sequence
  short: csq
  what: convert the current track to a sequence
  parameters: none
merge_sequence:
  type: sequence
  short: msq
  what: cache and MON the current sequence mix track, disable the sequence
  parameters: none
snip:
  type: sequence
  what: |
    create a sequence from the current track by removing 
    the region(s) defined by mark pair(s). Not supported if 
    the current track is already a sequence.
  example: |
    snip cut1-start cut1-end cut2-start cut2-end
    This removes cut1 and cut2 regions from the current track
    by creating a sequence. 
  parameters: <mark_pair1> [<mark_pair2>...]
compose:
  type: sequence
  short: compose_sequence compose_into_sequence
  what: |
    compose a new sequence using the region(s) of the named track
    defined by mark pair(s). If the sequence of that name exists, 
    append the regions to that sequence (compose_into_sequence).
  parameters: <string:sequence_name> <string:trackname> <mark_pair1> [<mark_pair2>...]
  example: |
    compose speeches conference-audio speaker1-start speaker1-end 
    speaker2-start speaker2-end
    This creates a "speeches" sequence with two clips
    for speaker1 and speaker2.
undo:
  type: general
  what: |
    roll back last commit (use "git log" to see specific commands)
    Note: redo is not supported yet
redo: 
  type: general
  what: restore the last undone commit (TODO)
show_head_commit:
  type: general
  short: show_head last_command last
  what: |
    show the last commit, which undo will roll back.
    A commit may contain multiple commands. 
    The last_* aliases are meaningful when autosave: undo is set.
    In that case each commit contains only a single command
eager:
  type: mode
  what: set eager mode
  parameters: on | off
new_engine:
  type: engine
  what: Start a named Ecasound engine, or bind to an existing engine
  short: neg
  parameters: <string:engine_name> <integer:port>
select_engine:
  type: engine
  what: Select an ecasound engine (advanced users only!)
  short: seg
  parameters: <string:engine_name>
set_track_engine_group:
  type: track
  what: set the current track's engine affiliation
  short: steg
  parameters: <string:engine_name>
set_bus_engine_group:
  type: bus
  what: set the current bus's engine affiliation
  short: sbeg
  parameters: <string:engine_name>
select_submix:
  type: bus
  short: ssm
  what: Set the target for the trim command
  parameters: <string:submix_name>
trim_submix:
  type: bus
  what: control a submix fader
  short: trim tsm
  example: |
    ! reduce vol of current track in in_ear_monitor by 3dB
    select_submix in_ear_monitor
    trim vol - 3 
nickname_effect:
  type: effect
  short: nfx nick
  what: Add a nickname to the current effect (and create an alias)
  parameters: <lower_case_string:nickname>
  example: |
    add_track guitar
    afx Plate
    nick reverb        # current effect gets name "reverb1"
                       # "reverb" becomes an alias for "Plate"
    mfx reverb1 1 0.05 # modify first reverb effect on current track 
    mfx reverb 1 2     # works, because current track has one effect named "reverb"
    afx reverb         # add another Plate effect, gets name "reverb2"
    
    rfx reverb         # Error, multiple reverb effects are present on this 
    !                  # track. Please use a numerical suffix.
    mfx reverb2 1 3    # modify second reverb effect
    rfx reverb1        # removes reverb1
    ifx reverb2 reverb # insert another reverb effect (reverb3) before reverb2
    rfx reverb3        # remove reverb3
    rfx reverb         # removes reverb2, as it is the sole remain reverb effect
delete_nickname_definition:
  type: effect
  short: dnd
  what: delete a nickname definition. Previously named effects keep their names.
  example: |
    afx Plate   # add Plate effect
    nick reverb # name it "reverb", and create a nickname for Plate
    dnd reverb  # removes nickname definition
    afx reverb  # error
remove_nickname:
  type: effect
  what: remove the "name" attribute of the current effect
  short: rnick
  example: |
    afx Plate
    nick reverb
    mfx reverb 1 3
    rnick
    mfx reverb 1 3 # Error: effect named "reverb" not found on current track
list_nickname_definitions:
  type: effect
  what: list defined nicknames
  short: lnd
  parameters: none
set_effect_name:
  type: effect
  what: set a nickname only (don't creating an alias)
  short: sen
  parameters: <string:name>
set_effect_surname:
  type: effect
  what: set an effect surname
  short: ses
  parameters: <string:surname>
remove_effect_name:
  type: effect
  what: remove current effect name
  short: ren
remove_effect_surname:
  type: effect
  what: remove current effect surname
  short: res
select_track:
  type: track
  what: |
    set a particular track as the current, or default track
    against which track-related commands are executed.
  parameters: <string:track-name> | <integer:track-number>
...

@@ grammar

command: _a_test { print "aaa-test" }
_a_test: /something_else\b/ | /a-test\b/
meta: midish_cmd 
midish_cmd: /[a-z]+/ predicate { 
	return unless $Audio::Nama::midi->{keywords}->{$item[1]};
	my $line = "$item[1] $item{predicate}";
	Audio::Nama::midish_command($line);
	1;
}
meta: bang shellcode stopper {
	Audio::Nama::logit(__LINE__,'Audio::Nama::Grammar','debug',"Evaluating shell commands!");
	my $shellcode = $item{shellcode};
	$shellcode =~ s/\$thiswav/$Audio::Nama::this_track->full_path/e;
	my $olddir = Audio::Nama::getcwd();
	my $prefix = "chdir ". Audio::Nama::project_dir().";";
	$shellcode = "$prefix $shellcode" if $shellcode =~ /^\s*git /;
	Audio::Nama::pager( "executing this shell code:  $shellcode" )
		if $shellcode ne $item{shellcode};
	my $output = qx( $shellcode );
	chdir $olddir;
	Audio::Nama::pager($output) if $output;
	1;
}
meta: eval perlcode stopper {
	Audio::Nama::logit(__LINE__,'Audio::Nama::Grammar','debug',"Evaluating perl code");
	Audio::Nama::eval_perl($item{perlcode});
	1
}
meta: for bunch_spec ';' namacode stopper { 
 	Audio::Nama::logit(__LINE__,'Grammar','debug',"namacode: $item{namacode}");
 	my @tracks = Audio::Nama::bunch_tracks($item{bunch_spec});
 	for my $t(@tracks) {
 		Audio::Nama::user_set_current_track($t);
		$Audio::Nama::text->{parser}->meta($item{namacode});
	}
	1;
}
bunch_spec: text 
meta: nosemi(s /\s*;\s*/) semicolon(?) 
nosemi: text { $Audio::Nama::text->{parser}->do_part($item{text}) }
text: /[^;]+/ 
semicolon: ';'
do_part: command end
do_part: track_spec command end
do_part: track_spec end
predicate: nonsemi end { $item{nonsemi}}
predicate: /$/
iam_cmd: ident { $item{ident} if $Audio::Nama::text->{iam}->{$item{ident}} }
track_spec: ident { Audio::Nama::user_set_current_track($item{ident}) }
bang: '!'
eval: 'eval'
for: 'for'
stopper: ';;' | /$/ 
shellcode: somecode 
perlcode: somecode 
namacode: somecode 
somecode: /.+?(?=;;|$)/ 
nonsemi: /[^;]+/
semistop: /;|$/
command: iam_cmd predicate { 
	my $user_input = "$item{iam_cmd} $item{predicate}"; 
	Audio::Nama::logit(__LINE__,'Audio::Nama::Grammar','debug',"Found Ecasound IAM command: $user_input");
	my $result = Audio::Nama::eval_iam($user_input);
	Audio::Nama::pager( $result );  
	1 }
command: user_command predicate {
	Audio::Nama::do_user_command(split " ",$item{predicate});
	1;
}
command: user_alias predicate {
	$Audio::Nama::text->{parser}->do_part("$item{user_alias} $item{predicate}"); 1
}
user_alias: ident { 
		$Audio::Nama::config->{alias}->{command}->{$item{ident}} }
user_command: ident { return $item{ident} if $Audio::Nama::text->{user_command}->{$item{ident}} }
key: /\w+/ 			
someval: /[\w.+-]+/ 
sign: '+' | '-' | '*' | '/' 
parameter_value: '*' | value
value: /[+-]?([\d_]+(\.\d*)?|\.\d+)([eE][+-]?\d+)?/
float: /\d+\.\d+/   
op_id: /[A-Z]+/		
existing_op_id: op_id
{
	my $FX; $FX = Audio::Nama::fxn($item[-1]) and $FX->id 
}
parameter: /\d+/	
dd: /\d+/			
shellish: /"(.+)"/ { $1 }
shellish: /'(.+)'/ { $1 }
shellish: anytag | <error>
jack_port: shellish
effect: /\w[^, ]+/
project_id: ident slash(?) { $item{ident} }
slash: '/'
anytag: /\S+/
ident: /[-\w]+/  
save_target: /[-:\w.]+/
decimal_seconds: /\d+(\.\d+)?/ 
marktime: /\d+\.\d+/ 
markname: /[A-Za-z]\w*/ { 
	Audio::Nama::throw("$item[1]: non-existent mark name. Skipping"), return undef 
		unless $Audio::Nama::Mark::by_name{$item[1]};
	$item[1];
}
path: shellish
modifier: 'audioloop' | 'select' | 'reverse' | 'playat' | value
end: /[;\s]*$/ 		
help_effect: _help_effect effect { Audio::Nama::help_effect($item{effect}) ; 1}
find_effect: _find_effect anytag(s) { 
	Audio::Nama::find_effect(@{$item{"anytag(s)"}}); 1}
help: _help anytag  { Audio::Nama::help($item{anytag}) ; 1}
help: _help { Audio::Nama::pager( $Audio::Nama::help->{screen} ); 1}
project_name: _project_name { 
	Audio::Nama::pager( "project name: ", $Audio::Nama::project->{name}); 1}
new_project: _new_project project_id { 
	Audio::Nama::t_create_project $item{project_id} ; 1}
list_projects: _list_projects { Audio::Nama::list_projects() ; 1}
load_project: _load_project project_id {
	Audio::Nama::t_load_project $item{project_id} ; 1}
new_project_template: _new_project_template key text(?) {
	Audio::Nama::new_project_template($item{key}, $item{text});
	1;
}
use_project_template: _use_project_template key {
	Audio::Nama::use_project_template($item{key}); 1;
}
list_project_templates: _list_project_templates {
	Audio::Nama::list_project_templates(); 1;
}
destroy_project_template: _destroy_project_template key(s) {
	Audio::Nama::remove_project_template(@{$item{'key(s)'}}); 1;
}
tag: _tag tagname message(?) {   
	Audio::Nama::git_snapshot();
	my @args = ('tag', $item{tagname});
	push @args, '-m', "@{$item{'message(?)'}}" if @{$item{'message(?)'}};
	Audio::Nama::git(@args);
	1;
}
commit: _commit message(?) { 
	Audio::Nama::git_snapshot(@{$item{'message(?)'}});
	1;
}
branch: _branch branchname { 
	Audio::Nama::throw("$item{branchname}: branch does not exist.  Skipping."), return 1
		if ! Audio::Nama::git_branch_exists($item{branchname});
	if(Audio::Nama::git_checkout($item{branchname})){
		Audio::Nama::load_project(name => $Audio::Nama::project->{name})
	} else { } 
	1;
}
branch: _branch { Audio::Nama::list_branches(); 1}
list_branches: _list_branches end { Audio::Nama::list_branches(); 1}
new_branch: _new_branch branchname branchfrom(?) { 
	my $name = $item{branchname};
	my $from = "@{$item{'branchfrom(?)'}}";
	Audio::Nama::throw("$name: branch already exists. Doing nothing."), return 1
		if Audio::Nama::git_branch_exists($name);
	Audio::Nama::git_create_branch($name, $from);
}
tagname: ident
branchname: ident
branchfrom: ident
message: /.+/
save_state: _save_state save_target message(?) { 
	my $name = $item{save_target};
	my $default_msg = "user save - $name";
	my $message = "@{$item{'message(?)'}}" || $default_msg;
	Audio::Nama::pager("save target name: $name\n");
	Audio::Nama::pager("commit message: $message\n") if $message;
	if(  ! $Audio::Nama::config->{use_git} or $name =~ /\.json$/ )
	{
	 	Audio::Nama::pager("saving as file\n"), Audio::Nama::save_state( $name)
	}
	else 
	{
		Audio::Nama::git_snapshot();
		my @args = ('tag', $name);
		push @args, '-m', $message if $message;
		Audio::Nama::git(@args);
		Audio::Nama::pager_newline(qq/tagged HEAD commit as "$name"/,
			qq/type "get $name" to return to this commit./)
	}
	1
}
save_state: _save_state { Audio::Nama::git_snapshot('user save'); 1}
get_state: _get_state save_target {
 	Audio::Nama::load_project( 
 		name => $Audio::Nama::project->{name},
 		settings => $item{save_target}
 		); 1}
getpos: _getpos {  
	Audio::Nama::pager( Audio::Nama::d1( Audio::Nama::eval_iam q(getpos) )); 1}
setpos: _setpos timevalue {
	Audio::Nama::set_position($item{timevalue}); 1}
forward: _forward timevalue {
	Audio::Nama::forward( $item{timevalue} ); 1}
rewind: _rewind timevalue {
	Audio::Nama::rewind( $item{timevalue} ); 1}
timevalue: min_sec | decimal_seconds
seconds: samples  
seconds: /\d+/
samples: /\d+sa/ {
	my ($samples) = $item[1] =~ /(\d+)/;
 	$return = $samples/$Audio::Nama::config->{sample_rate}
}
min_sec: /\d+/ ':' /\d+/ { $item[1] * 60 + $item[3] }
to_start: _to_start { Audio::Nama::to_start(); 1 }
to_end: _to_end { Audio::Nama::to_end(); 1 }
add_track: _add_track new_track_name {
	Audio::Nama::add_track($item{new_track_name});
    1
}
add_midi_track: _add_midi_track new_track_name {
	Audio::Nama::MidiTrack->new(name => $item{new_track_name}, group => 'Midi');
	Audio::Nama::pager_newline(qq(creating MIDI track "$item{new_track_name}"));
	1
}
arg: anytag
add_tracks: _add_tracks track_name(s) {
	map{ Audio::Nama::add_track($_)  } @{$item{'track_name(s)'}}; 1}
new_track_name: anytag  { 
  	my $proposed = $item{anytag};
  	Audio::Nama::throw( qq(Track name "$proposed" needs to start with a letter)), 
  		return undef if  $proposed !~ /^[A-Za-z]/;
  	Audio::Nama::throw( qq(Track name "$proposed" cannot contain a colon.)), 
  		return undef if  $proposed =~ /:/;
 	Audio::Nama::throw( qq(A track named "$proposed" already exists.)), 
 		return undef if $Audio::Nama::Track::by_name{$proposed};
 	Audio::Nama::throw( qq(Track name "$proposed" conflicts with Ecasound command keyword.)), 
 		return undef if $Audio::Nama::text->{iam}->{$proposed};
 	Audio::Nama::throw( qq(Track name "$proposed" conflicts with user command.)), 
 		return undef if $Audio::Nama::text->{user_command}->{$proposed};
  	Audio::Nama::throw( qq(Track name "$proposed" conflicts with Nama command or shortcut.)), 
  		return undef if $Audio::Nama::text->{commands}->{$proposed} 
				 or $Audio::Nama::text->{command_shortcuts}->{$proposed}; 
;
$proposed
} 
track_name: ident
existing_track_name: track_name { 
	my $track_name = $item{track_name};
	if ($Audio::Nama::tn{$track_name}){
		$track_name;
	}
	else {	
		Audio::Nama::throw("$track_name: track does not exist.\n");
		undef
	}
}
move_to_bus: _move_to_bus existing_bus_name {
	$Audio::Nama::this_track->set( group => $item{existing_bus_name}); 1
} 
set_track: _set_track key someval {
	 $Audio::Nama::this_track->set( $item{key}, $item{someval} ); 1}
dump_track: _dump_track { Audio::Nama::pager($Audio::Nama::this_track->dump); 1}
dump_group: _dump_group { Audio::Nama::pager($Audio::Nama::bn{Main}->dump); 1}
dump_all: _dump_all { Audio::Nama::dump_all(); 1}
remove_track: _remove_track quiet end {
	local $Audio::Nama::quiet = 1;
	Audio::Nama::remove_track_cmd($Audio::Nama::this_track);
	1
}
remove_track: _remove_track existing_track_name {
		Audio::Nama::remove_track_cmd($Audio::Nama::tn{$item{existing_track_name}});
		1
}
remove_track: _remove_track end { 
		Audio::Nama::remove_track_cmd($Audio::Nama::this_track) ;
		1
}
quiet: 'quiet'
link_track: _link_track existing_project_name track_name new_track_name end
{
	Audio::Nama::add_track_alias_project(
		$item{new_track_name},
		$item{track_name}, 
		$item{existing_project_name}
	); 
1
}
link_track: _link_track target track_name end {
	Audio::Nama::add_track_alias($item{track_name}, $item{target}); 1
}
target: existing_track_name
existing_project_name: ident {
	$item{ident} if -d Audio::Nama::join_path(Audio::Nama::project_root(),$item{ident})
}
project: ident
set_region: _set_region beginning ending { 
	Audio::Nama::set_region( @item{ qw( beginning ending ) } );
	1;
}
set_region: _set_region beginning { Audio::Nama::set_region( $item{beginning}, 'END' );
	1;
}
remove_region: _remove_region { Audio::Nama::remove_region(); 1; }
add_region: _add_region beginning ending track_name(?) {
	my $name = $item{'track_name(?)'}->[0];
	Audio::Nama::new_region(@item{qw(beginning ending)}, $name); 1
}
shift_track: _shift_track start_position {
	my $pos = $item{start_position};
	if ( $pos =~ /\d+\.\d+/ ){
		Audio::Nama::pager($Audio::Nama::this_track->name, ": Shifting start time to $pos seconds");
		$Audio::Nama::this_track->set(playat => $pos);
		1;
	}
	elsif ( $Audio::Nama::Mark::by_name{$pos} ){
		my $time = Audio::Nama::Mark::mark_time( $pos );
		Audio::Nama::pager($Audio::Nama::this_track->name, qq(: Shifting start time to mark "$pos", $time seconds));
		$Audio::Nama::this_track->set(playat => $pos);
		1;
	} else { 
		Audio::Nama::throw( "Shift value is neither decimal nor mark name. Skipping.");
	0;
	}
}
start_position:  float | samples | mark_name
mark_name: ident
unshift_track: _unshift_track {
	$Audio::Nama::this_track->set(playat => undef)
}
beginning: marktime | markname
ending: 'END' | marktime | markname 
generate: _generate { Audio::Nama::generate_setup(); 1}
arm: _arm { Audio::Nama::arm(); 1}
arm_start: _arm_start { Audio::Nama::arm(); Audio::Nama::start_transport(); 1 }
connect: _connect { Audio::Nama::connect_transport(); 1}
disconnect: _disconnect { Audio::Nama::disconnect_transport(); 1}
engine_status: _engine_status { Audio::Nama::pager(Audio::Nama::eval_iam q(engine-status)); 1}
start: _start { Audio::Nama::start_transport(); 1}
stop: _stop { Audio::Nama::stop_transport(); 1}
ecasound_start: _ecasound_start { Audio::Nama::eval_iam('start'); 1}
ecasound_stop: _ecasound_stop  { Audio::Nama::eval_iam('stop'); 1}
restart_ecasound: _restart_ecasound { Audio::Nama::restart_ecasound(); 1 }
show_tracks: _show_tracks { 	
	Audio::Nama::pager( Audio::Nama::show_tracks(Audio::Nama::showlist()));
	1;
}
show_tracks_all: _show_tracks_all { 	
	my $list = [undef, undef, sort{$a->n <=> $b->n} Audio::Nama::all_tracks()];
	Audio::Nama::pager(Audio::Nama::show_tracks($list));
	1;
}
show_bus_tracks: _show_bus_tracks { 	
	my $bus = $Audio::Nama::bn{$Audio::Nama::this_bus};
	my $list = $bus->trackslist;
	Audio::Nama::pager(Audio::Nama::show_tracks($list));
	1;
}
modifiers: _modifiers modifier(s) {
 	$Audio::Nama::this_track->set(modifiers => (join q(,),
	@{$item{"modifier(s)"}}, q() ));
	1;}
modifiers: _modifiers { Audio::Nama::pager( $Audio::Nama::this_track->modifiers); 1}
nomodifiers: _nomodifiers { $Audio::Nama::this_track->set(modifiers => ""); 1}
show_chain_setup: _show_chain_setup { Audio::Nama::pager(Audio::Nama::ChainSetup::ecasound_chain_setup); 1}
dump_io: _dump_io { Audio::Nama::ChainSetup::show_io(); 1}
show_track: _show_track {
	my $output = $Audio::Nama::text->{format_top};
	$output .= Audio::Nama::show_tracks_section($Audio::Nama::this_track);
	$output .= Audio::Nama::show_track_comment($Audio::Nama::this_track);
	$output .= Audio::Nama::show_region();
	$output .= Audio::Nama::show_versions();
	$output .= Audio::Nama::show_version_comment($Audio::Nama::this_track, $Audio::Nama::this_track->version);
	$output .= Audio::Nama::show_send();
	$output .= Audio::Nama::show_bus();
	$output .= Audio::Nama::show_modifiers();
	$output .= join "", "Signal width: ", Audio::Nama::width($Audio::Nama::this_track->width), "\n";
	$output .= Audio::Nama::show_inserts();
	$output .= Audio::Nama::show_effects();
	Audio::Nama::pager( $output );
	1;}
show_track: _show_track track_name { 
 	Audio::Nama::pager( Audio::Nama::show_tracks( 
	$Audio::Nama::tn{$item{track_name}} )) if $Audio::Nama::tn{$item{track_name}};
	1;}
show_track: _show_track dd {  
	Audio::Nama::pager( Audio::Nama::show_tracks( $Audio::Nama::ti{$item{dd}} )) if
	$Audio::Nama::ti{$item{dd}};
	1;}
show_mode: _show_mode { Audio::Nama::pager( Audio::Nama::show_status()); 1}
bus_mon: _bus_mon {
	my $bus = $Audio::Nama::bn{$Audio::Nama::this_bus}; 
	$bus->set(rw => 'MON');
	$Audio::Nama::tn{$bus->send_id}->busify
		if $bus->send_type eq 'track' and $Audio::Nama::tn{$bus->send_id};
	Audio::Nama::pager( "Setting MON mode for $Audio::Nama::this_bus bus.");
	1; }
bus_off: _bus_off {
	my $bus = $Audio::Nama::bn{$Audio::Nama::this_bus}; 
	$bus->set(rw => Audio::Nama::OFF);
	if($bus->send_type eq 'track' and my $mix = $Audio::Nama::tn{$bus->send_id})
	{ $mix->set(rw => Audio::Nama::OFF) }
	Audio::Nama::pager( "Setting OFF mode for " , $Audio::Nama::this_bus, " bus. Member tracks disabled."); 1  
}
bus_version: _bus_version dd { 
	my $n = $item{dd};
	Audio::Nama::process_command("for $Audio::Nama::this_bus; version $n");
}
mixdown: _mixdown { Audio::Nama::mixdown(); 1}
mixplay: _mixplay { Audio::Nama::mixplay(); 1}
mixoff:  _mixoff  { Audio::Nama::mixoff(); 1}
automix: _automix { Audio::Nama::automix(); 1 }
autofix_tracks: _autofix_tracks { Audio::Nama::process_command("for mon; fixdc; normalize"); 1 }
master_on: _master_on { Audio::Nama::master_on(); 1 }
master_off: _master_off { Audio::Nama::master_off(); 1 }
exit: _exit {   
	Audio::Nama::save_state(); 
	Audio::Nama::cleanup_exit();
	CORE::exit;
}	
source: _source ('track'|'t') trackname { 
	$Audio::Nama::this_track->set_source($item{trackname}, 'track'); 1
} 
trackname: existing_track_name
source: _source source_id { $Audio::Nama::this_track->set_source($item{source_id}); 1 }
source_id: shellish
source: _source { 
	my $status = $Audio::Nama::this_track->rec_status;
	Audio::Nama::pager_newline($Audio::Nama::this_track->name, ": input set to ", $Audio::Nama::this_track->input_object_text, "\n",
	"however track status is ", $status)
		if $status ne Audio::Nama::REC and $status ne Audio::Nama::MON;
	1;
}
send: _send ('track'|'t') trackname { 
	$Audio::Nama::this_track->set_send($item{trackname}, 'track'); 1
} 
send: _send send_id { $Audio::Nama::this_track->set_send($item{send_id}); 1}
send: _send { $Audio::Nama::this_track->set_send(); 1}
send_id: shellish
remove_send: _remove_send {
					$Audio::Nama::this_track->set(send_type => undef);
					$Audio::Nama::this_track->set(send_id => undef); 1
}
stereo: _stereo { 
	$Audio::Nama::this_track->set(width => 2); 
	Audio::Nama::pager($Audio::Nama::this_track->name, ": setting to stereo\n");
	1;
}
mono: _mono { 
	$Audio::Nama::this_track->set(width => 1); 
	Audio::Nama::pager($Audio::Nama::this_track->name, ": setting to mono\n");
	1; }
off: 'dummy'
record: 'dummy'
mon: 'dummy'
play: 'dummy'
command: mono
command: rw
rw_setting:   'REC ' | 'rec' 
			| 'PLAY' | 'play'
			| 'MON'  | 'mon'
			| 'OFF'  | 'off' { $return = $item[1] }
rw: rw_setting {
	$Audio::Nama::this_track->is_system_track 
		? $Audio::Nama::this_track->set(rw => uc $item{rw_setting}) 
		: Audio::Nama::rw_set($Audio::Nama::Bus::by_name{$Audio::Nama::this_bus},$Audio::Nama::this_track,$item{rw_setting}); 
	1
}
set_version: _set_version dd { $Audio::Nama::this_track->set_version($item{dd}); 1}
vol: _vol value { 
	$Audio::Nama::this_track->vol or 
		Audio::Nama::throw(( $Audio::Nama::this_track->name . ": no volume control available")), return;
	Audio::Nama::modify_effect(
		$Audio::Nama::this_track->vol,
		1,
		undef,
		$item{value});
	1;
} 
vol: _vol sign(?) value { 
	$Audio::Nama::this_track->vol or 
		Audio::Nama::throw( $Audio::Nama::this_track->name . ": no volume control available"), return;
	Audio::Nama::modify_effect(
		$Audio::Nama::this_track->vol,
		1,
		$item{'sign(?)'}->[0],
		$item{value});
	1;
} 
vol: _vol { Audio::Nama::pager( $Audio::Nama::this_track->vol_level); 1}
mute: _mute { $Audio::Nama::this_track->mute; 1}
unmute: _unmute { $Audio::Nama::this_track->unmute; 1}
solo: _solo ident(s) {
	Audio::Nama::solo(@{$item{'ident(s)'}}); 1
}
solo: _solo { Audio::Nama::solo($Audio::Nama::this_track->name); 1}
all: _all { Audio::Nama::all() ; 1}
nosolo: _nosolo { Audio::Nama::nosolo() ; 1}
unity: _unity { Audio::Nama::unity($Audio::Nama::this_track); 1}
pan: _pan panval { 
	Audio::Nama::update_effect( $Audio::Nama::this_track->pan, 0, $item{panval});
	1;} 
pan: _pan sign panval {
	Audio::Nama::modify_effect( $Audio::Nama::this_track->pan, 1, $item{sign}, $item{panval} );
	1;} 
panval: float 
      | dd
pan: _pan { Audio::Nama::pager( $Audio::Nama::this_track->pan_level); 1}
pan_right: _pan_right { Audio::Nama::pan_check($Audio::Nama::this_track, 100 ); 1}
pan_left:  _pan_left  { Audio::Nama::pan_check($Audio::Nama::this_track,    0 ); 1}
pan_center: _pan_center { Audio::Nama::pan_check($Audio::Nama::this_track,   50 ); 1}
pan_back:  _pan_back { Audio::Nama::pan_back($Audio::Nama::this_track); 1;}
remove_mark: _remove_mark dd {
	my @marks = Audio::Nama::Mark::all();
	$marks[$item{dd}]->remove if defined $marks[$item{dd}];
	1;}
remove_mark: _remove_mark ident { 
	my $mark = $Audio::Nama::Mark::by_name{$item{ident}};
	$mark->remove if defined $mark;
	1;}
remove_mark: _remove_mark { 
	return unless (ref $Audio::Nama::this_mark) =~ /Mark/;
	$Audio::Nama::this_mark->remove;
	1;}
add_mark: _add_mark ident { Audio::Nama::drop_mark $item{ident}; 1}
add_mark: _add_mark {  Audio::Nama::drop_mark(); 1}
next_mark: _next_mark { Audio::Nama::next_mark(); 1}
previous_mark: _previous_mark { Audio::Nama::previous_mark(); 1}
loop: _loop someval(s) {
	my @new_endpoints = @{ $item{"someval(s)"}}; 
	$Audio::Nama::mode->{loop_enable} = 1;
	@{$Audio::Nama::setup->{loop_endpoints}} = (@new_endpoints, @{$Audio::Nama::setup->{loop_endpoints}}); 
	@{$Audio::Nama::setup->{loop_endpoints}} = @{$Audio::Nama::setup->{loop_endpoints}}[0,1];
	1;}
noloop: _noloop { $Audio::Nama::mode->{loop_enable} = 0; 1}
name_mark: _name_mark ident {$Audio::Nama::this_mark->set_name( $item{ident}); 1}
list_marks: _list_marks { 
	my $i = 0;
	my @lines = map{ ( $_->{time} == $Audio::Nama::this_mark->{time} ? q(*) : q()
	,join " ", $i++, sprintf("%.1f", $_->{time}), $_->name, "\n")  } 
		  @Audio::Nama::Mark::all;
	my $start = my $end = "undefined";
	push @lines, "now at ". sprintf("%.1f", Audio::Nama::eval_iam "getpos"). "\n";
	Audio::Nama::pager(@lines);
	1;}
to_mark: _to_mark dd {
	my @marks = Audio::Nama::Mark::all();
	$marks[$item{dd}]->jump_here;
	1;}
to_mark: _to_mark ident { 
	my $mark = $Audio::Nama::Mark::by_name{$item{ident}};
	$mark->jump_here if defined $mark;
	1;}
modify_mark: _modify_mark sign value {
	my $newtime = eval($Audio::Nama::this_mark->{time} . $item{sign} . $item{value});
	$Audio::Nama::this_mark->set( time => $newtime );
	Audio::Nama::pager($Audio::Nama::this_mark->name, ": set to ", Audio::Nama::d2( $newtime), "\n");
	Audio::Nama::pager("adjusted to ",$Audio::Nama::this_mark->time, "\n") 
		if $Audio::Nama::this_mark->time != $newtime;
	Audio::Nama::set_position($Audio::Nama::this_mark->time);
	Audio::Nama::request_setup();
	1;
	}
modify_mark: _modify_mark value {
	$Audio::Nama::this_mark->set( time => $item{value} );
	my $newtime = $item{value};
	Audio::Nama::pager($Audio::Nama::this_mark->name, ": set to ", Audio::Nama::d2($newtime),"\n");
	Audio::Nama::pager("adjusted to ",$Audio::Nama::this_mark->time, "\n")
		if $Audio::Nama::this_mark->time != $newtime;
	Audio::Nama::set_position($Audio::Nama::this_mark->time);
	Audio::Nama::request_setup();
	1;
	}		
remove_effect: _remove_effect remove_target(s) {
	Audio::Nama::mute();
	map{ 
		my $id = $_;
		my ($use) = grep{ $id eq $Audio::Nama::this_track->$_ } qw(vol pan fader);
		if($use){
			Audio::Nama::throw("Effect $id is used as $use by track",$Audio::Nama::this_track->name, 
			".\nSee 'remove_fader_effect to remove it'\n")
		}
		else { 
			my $FX = Audio::Nama::fxn($id);
			Audio::Nama::pager_newline("removing effect ".$FX->nameline);
			$FX->_remove_effect();
		}
	} grep { $_ }  map{ split ' ', $_} @{ $item{"remove_target(s)"}} ;
	Audio::Nama::sleeper(0.5);
	Audio::Nama::unmute();
	1;}
add_controller: _add_controller parent effect value(s?) {
	my $code = $item{effect};
	my $parent = $item{parent};
	my $parent_o = Audio::Nama::fxn($parent);
	print "parent: ", $parent_o, " chain: ", $parent_o->chain;
	my $values = $item{"value(s?)"};
	my $id = Audio::Nama::add_effect({
		parent	=> $parent, 
		chain	=> $parent_o->chain,
		type 	=> $code, 
		params	=> $values,
	});
	if($id)
	{
		my $iname = Audio::Nama::fxn($id)->fxname;
		my $pname = Audio::Nama::fxn($parent)->fxname;
		Audio::Nama::pager("\nAdded $id, $iname to $parent, $pname\n\n");
	}
	1;
}
add_controller: _add_controller effect value(s?) {
	Audio::Nama::throw("current effect is undefined, skipping\n"), return 1 if ! Audio::Nama::this_op();
	my $code = $item{effect};
	my $parent = Audio::Nama::this_op();
	my $values = $item{"value(s?)"};
	my $cmd = "add_controller $parent $code @$values";
	print "command: $cmd\n";
	Audio::Nama::process_command($cmd);
	1
}
existing_effect_chain: ident { $item{ident} if Audio::Nama::is_effect_chain($item{ident}) }
add_target: fx_nick | existing_effect_chain | known_effect_type
nickname_effect: _nickname_effect ident {
	my $ident = $item{ident};
	Audio::Nama::this_op_o()->set_name($ident);
	Audio::Nama::throw("$ident: no such nickname. Skipping."), return unless defined Audio::Nama::this_op_o();
	my $type = Audio::Nama::this_op_o()->type;
	my $fxname = Audio::Nama::this_op_o()->fxname;
	$Audio::Nama::fx->{alias}->{$ident} = $type;
	Audio::Nama::pager_newline("$ident: nickname created for $type ($fxname)");
	1
}
remove_nickname: _remove_nickname { Audio::Nama::this_op_o()->remove_name() }
delete_nickname_definition: _delete_nickname_definition ident {
	my $was = delete $Audio::Nama::fx->{alias}->{$item{ident}};
	$was or Audio::Nama::throw("$item{ident}: no such nickname"), return 0;
	Audio::Nama::pager_newline("$item{ident}: effect nickname deleted");
}
list_nickname_definitions: _list_nickname_definitions {
	my @lines;
	while( my($nick,$code) = each %{ $Audio::Nama::fx->{alias} } )
	{
		push @lines, join " ",
			"$nick:",
			$Audio::Nama::fx_cache->{registry}->[Audio::Nama::effect_index($code)]->{name},
			"($code)\n";
	}
	Audio::Nama::pager(@lines);
	1
}
known_effect_type: effect { 
	Audio::Nama::full_effect_code($item{effect})
}
before: fx_alias
fx_name: ident { $Audio::Nama::this_track->effect_id_by_name($item{ident}) }
fx_surname: ident { $Audio::Nama::this_track->with_surname($item{ident}) }
add_effect: _add_effect add_target parameter_value(s?) before(?) {
	my ($code, $effect_chain);
	my $values = $item{'parameter_value(s?)'};
	my $args = { 	track  => $Audio::Nama::this_track, 
					params	=> $values };
	if( my $fxc = Audio::Nama::is_effect_chain($item{add_target}) )
	{ 
				$args->{effect_chain}	= $fxc
	}
	else{ 	  	$args->{type}			= $item{add_target}				}
	my $fader = 
			   Audio::Nama::fxn($Audio::Nama::this_track->pan) && $Audio::Nama::this_track->pan
			|| Audio::Nama::fxn($Audio::Nama::this_track->vol) && $Audio::Nama::this_track->vol;
	{ no warnings 'uninitialized';
	Audio::Nama::logpkg(__FILE__,__LINE__,'debug',$Audio::Nama::this_track->name,": effect insert point is $fader", 
	Audio::Nama::Dumper($args));
	}
	my $predecessor = $item{'before(?)'}->[0] || $fader;
	$args->{before} = $predecessor if $predecessor; 
	my $added = Audio::Nama::_add_effect($args);
	for my $FX(@$added)
	{
		my $iname = $FX->fxname;
		my $id = $FX->id;
		Audio::Nama::pager_newline("Added $id, $iname");
		Audio::Nama::set_current_op($id);
	}
}
add_effect: _add_effect ('first'  | 'f')  add_target value(s?) {
	my $command = join " ", 
		qw(add_effect), 
		$item{add_target},
		@{$item{'value(s?)'}},
		$Audio::Nama::this_track->{ops}->[0];
	Audio::Nama::process_command($command)
}
add_effect: _add_effect ('last'   | 'l')  add_target value(s?) { 
	my $command = join " ", 
		qw(add_effect),
		$item{add_target},
		@{$item{'value(s?)'}},
		qw(ZZZ);
	Audio::Nama::process_command($command)
}
add_effect: _add_effect ('before' | 'b')  before add_target value(s?) {
	my $command = join " ", 
		qw(add_effect),
		$item{add_target},
		@{$item{'value(s?)'}},
		$item{before};
	Audio::Nama::process_command($command)
}
add_effect_first: _add_effect_first add_target value(s?) {
	my $command = join " ", 
		qw(add_effect),
		"last",
		$item{add_target},
		@{$item{'value(s?)'}};
	Audio::Nama::process_command($command)
}
add_effect_last: _add_effect_last add_target value(s?) {
	my $command = join " ", 
		qw(add_effect),
		"last",
		$item{add_target},
		@{$item{'value(s?)'}};
	Audio::Nama::process_command($command)
}
add_effect_before: _add_effect_before before add_target value(s?) {
	my $command = join " ", 
		qw(add_effect),
		"before",
		$item{before},		
		$item{add_target},
		@{$item{'value(s?)'}};
	Audio::Nama::process_command($command)
}
parent: op_id
modify_effect: _modify_effect fx_alias(s /,/) parameter(s /,/) value {
	Audio::Nama::modify_multiple_effects( @item{qw(fx_alias(s) parameter(s) sign value)});
	Audio::Nama::pager(Audio::Nama::show_effect(@{ $item{'fx_alias(s)'} }))
}
modify_effect: _modify_effect fx_alias(s /,/) parameter(s /,/) sign value {
	Audio::Nama::modify_multiple_effects( @item{qw(fx_alias(s) parameter(s) sign value)});
	Audio::Nama::pager(Audio::Nama::show_effect(@{ $item{'fx_alias(s)'} }));
}
modify_effect: _modify_effect parameter(s /,/) value {
	Audio::Nama::throw("current effect is undefined, skipping"), return 1 if ! Audio::Nama::this_op();
	Audio::Nama::modify_multiple_effects( 
		[Audio::Nama::this_op()], 
		$item{'parameter(s)'},
		undef,
		$item{value});
	Audio::Nama::pager( Audio::Nama::show_effect(Audio::Nama::this_op(), "with track affiliation"))
}
modify_effect: _modify_effect parameter(s /,/) sign value {
	Audio::Nama::throw("current effect is undefined, skipping"), return 1 if ! Audio::Nama::this_op();
	Audio::Nama::modify_multiple_effects( [Audio::Nama::this_op()], @item{qw(parameter(s) sign value)});
	Audio::Nama::pager( Audio::Nama::show_effect(Audio::Nama::this_op()));
}
fx_alias3: ident { 
	join " ", 
	map{ $_->id } 
	grep { $_->surname eq $item{ident} } $Audio::Nama::this_track->fancy_ops_o;
}
remove_target: existing_op_id | fx_pos | fx_surname | fx_name
	{ $item[-1] or print("no effect object found\n"), return 0}
fx_alias: fx_alias2 | fx_alias1
fx_nick: ident { $Audio::Nama::fx->{alias}->{$item{ident}} }
fx_alias1: op_id
fx_alias1: fx_pos
fx_alias1: fx_name
fx_alias2: fx_type
fx_pos: dd { $Audio::Nama::this_track->{ops}->[$item{dd} - 1] }
fx_type: effect { 
	my $FX = $Audio::Nama::this_track->first_effect_of_type($item{effect});
	$FX ? $FX->id : undef
}
position_effect: _position_effect op_to_move new_following_op {
	my $op = $item{op_to_move};
	my $pos = $item{new_following_op};
	my $FX = Audio::Nama::fxn($op);
	$FX->position_effect($pos);
	Audio::Nama::set_current_op($op);
	1;
}
op_to_move: op_id
new_following_op: op_id
show_effect: _show_effect fx_alias(s) {
	my @fx = @{ $item{'fx_alias(s)'}};
	@fx = Audio::Nama::Effect::expanded_ops_list(@fx);
	my @lines = 
		map{ Audio::Nama::show_effect($_, "with track affiliation") } 
		grep{ Audio::Nama::fxn($_) }
		@fx;
	Audio::Nama::set_current_op($item{'fx_alias(s)'}->[-1]);
	Audio::Nama::pager(@lines); 1
}
show_effect: _show_effect {
	Audio::Nama::throw("current effect is undefined, skipping"), return 1 if ! Audio::Nama::this_op();
	Audio::Nama::pager( Audio::Nama::show_effect(Audio::Nama::this_op(), "with track affiliation"));
	1;
}
dump_effect: _dump_effect fx_alias { Audio::Nama::pager( Audio::Nama::json_out(Audio::Nama::fxn($item{fx_alias})->as_hash) ); 1}
dump_effect: _dump_effect { Audio::Nama::pager( Audio::Nama::json_out(Audio::Nama::this_op_o()->as_hash) ); 1}
list_effects: _list_effects { Audio::Nama::pager(Audio::Nama::list_effects()); 1}
add_bunch: _add_bunch ident(s) { Audio::Nama::bunch( @{$item{'ident(s)'}}); 1}
list_bunches: _list_bunches { Audio::Nama::bunch(); 1}
remove_bunch: _remove_bunch ident(s) { 
 	map{ delete $Audio::Nama::project->{bunch}->{$_} } @{$item{'ident(s)'}}; 1}
add_to_bunch: _add_to_bunch ident(s) { Audio::Nama::add_to_bunch( @{$item{'ident(s)'}});1 }
list_versions: _list_versions { 
	Audio::Nama::pager( join " ", @{$Audio::Nama::this_track->versions}); 1}
ladspa_register: _ladspa_register { 
	Audio::Nama::pager( Audio::Nama::eval_iam("ladspa-register")); 1}
preset_register: _preset_register { 
	Audio::Nama::pager( Audio::Nama::eval_iam("preset-register")); 1}
ctrl_register: _ctrl_register { 
	Audio::Nama::pager( Audio::Nama::eval_iam("ctrl-register")); 1}
preview: _preview { Audio::Nama::set_preview_mode(); 1}
doodle: _doodle { Audio::Nama::set_doodle_mode(); 1 }
normalize: _normalize { $Audio::Nama::this_track->normalize; 1}
fixdc: _fixdc { $Audio::Nama::this_track->fixdc; 1}
destroy_current_wav: _destroy_current_wav { Audio::Nama::destroy_current_wav(); 1 }
memoize: _memoize { 
	package Audio::Nama::Wav;
	$Audio::Nama::config->{memoize} = 1;
	memoize('candidates'); 1
}
unmemoize: _unmemoize {
	package Audio::Nama::Wav;
	$Audio::Nama::config->{memoize} = 0;
	unmemoize('candidates'); 1
}
import_audio: _import_audio path frequency {
	Audio::Nama::import_audio($Audio::Nama::this_track, $item{path}, $item{frequency}); 1;
}
import_audio: _import_audio path {
	Audio::Nama::import_audio($Audio::Nama::this_track, $item{path}); 1;
}
frequency: value
list_history: _list_history {
	my @history = $Audio::Nama::text->{term}->GetHistory;
	my %seen;
	Audio::Nama::pager( grep{ ! $seen{$_} and $seen{$_}++ } @history );
}
add_submix_cooked: _add_submix_cooked bus_name destination {
	Audio::Nama::add_submix( $item{bus_name}, $item{destination}, 'cooked' );
	1;
}
add_submix_raw: _add_submix_raw bus_name destination {
	Audio::Nama::add_submix( $item{bus_name}, $item{destination}, 'raw' );
	1;
}
add_bus: _add_bus bus_name { Audio::Nama::add_bus( $item{bus_name}); 1 }
existing_bus_name: bus_name {
	if ( $Audio::Nama::bn{$item{bus_name}} ){  $item{bus_name} }
	else { Audio::Nama::throw("$item{bus_name}: no such bus"); undef }
}
bus_name: ident 
user_bus_name: ident 
{
	if($item[1] =~ /^[A-Z]/){ $item[1] }
	else { Audio::Nama::throw("Bus name must begin with capital letter."); undef} 
}
destination: jack_port 
remove_bus: _remove_bus existing_bus_name { 
	$Audio::Nama::bn{$item{existing_bus_name}}->remove; 1; 
}
update_submix: _update_submix existing_bus_name {
 	Audio::Nama::update_submix( $item{existing_bus_name} );
 	1;
}
set_bus: _set_bus key someval { $Audio::Nama::bn{$Audio::Nama::this_bus}->set($item{key} => $item{someval}); 1 }
list_buses: _list_buses { Audio::Nama::pager(map{ $_->dump } Audio::Nama::Bus::all()) ; 1}
add_insert: _add_insert 'local' {
	Audio::Nama::Insert::add_insert( $Audio::Nama::this_track,'postfader_insert');
	1;
}
add_insert: _add_insert prepost send_id return_id(?) {
	my $return_id = $item{'return_id(?)'}->[0];
	my $send_id = $item{send_id};
	Audio::Nama::Insert::add_insert($Audio::Nama::this_track, "$item{prepost}fader_insert",$send_id, $return_id);
	1;
}
prepost: 'pre' | 'post'
send_id: jack_port
return_id: jack_port
set_insert_wetness: _set_insert_wetness prepost(?) parameter {
	my $prepost = $item{'prepost(?)'}->[0];
	my $p = $item{parameter};
	my $id = Audio::Nama::Insert::get_id($Audio::Nama::this_track,$prepost);
	Audio::Nama::throw($Audio::Nama::this_track->name.  ": Missing or ambiguous insert. Skipping"), 
		return 1 unless $id;
	Audio::Nama::throw("wetness parameter must be an integer between 0 and 100"), 
		return 1 unless ($p <= 100 and $p >= 0);
	my $i = $Audio::Nama::Insert::by_index{$id};
	Audio::Nama::throw("track '",$Audio::Nama::this_track->n, "' has no insert.  Skipping."),
		return 1 unless $i;
	$i->set_wetness($p);
	1;
}
set_insert_wetness: _set_insert_wetness prepost(?) {
	my $prepost = $item{'prepost(?)'}->[0];
	my $id = Audio::Nama::Insert::get_id($Audio::Nama::this_track,$prepost);
	$id or Audio::Nama::throw($Audio::Nama::this_track->name.  ": Missing or ambiguous insert. Skipping"), return 1 ;
	my $i = $Audio::Nama::Insert::by_index{$id};
	 Audio::Nama::pager( "The insert is ", $i->wetness, "% wet, ", (100 - $i->wetness), "% dry.");
}
remove_insert: _remove_insert prepost(?) { 
	my $prepost = $item{'prepost(?)'}->[0];
	my $id = Audio::Nama::Insert::get_id($Audio::Nama::this_track,$prepost);
	$id or Audio::Nama::throw($Audio::Nama::this_track->name.  ": Missing or ambiguous insert. Skipping"), return 1 ;
	Audio::Nama::pager( $Audio::Nama::this_track->name.": removing ". $prepost ?  "$prepost fader insert" : "insert");
	$Audio::Nama::Insert::by_index{$id}->remove;
	1;
}
cache_track: _cache_track additional_time(?) {
	my $time = $item{'additional_time(?)'}->[0];
	Audio::Nama::cache_track($Audio::Nama::this_track, $time); 1 
}
additional_time: float | dd
uncache_track: _uncache_track { Audio::Nama::uncache_track($Audio::Nama::this_track); 1 }
overwrite_effect_chain: 'dummy' 
new_effect_chain: (_new_effect_chain | _overwrite_effect_chain ) ident op_id(s?) end {
 	my $name = $item{ident};
	my @existing = Audio::Nama::EffectChain::find(user => 1, name => $name);
	if ( scalar @existing ){
		$item[1] eq 'overwrite_effect_chain'
 			? Audio::Nama::process_command("delete_effect_chain $name")
 			: Audio::Nama::throw(qq/$name: effect chain with this name is already defined. 
Use a different name, or use "overwrite_effect_chain"/) && return;
	}
	my $ops = scalar @{$item{'op_id(s?)'}}
				?  $item{'op_id(s?)'} 
				: [ $Audio::Nama::this_track->fancy_ops ];
	my @options;
	Audio::Nama::EffectChain->new(
		user   => 1,
		global => 1,
		name   => $item{ident},
		ops_list => $ops,
		inserts_data => $Audio::Nama::this_track->inserts,
		@options,
	);
	1;
}
delete_effect_chain: _delete_effect_chain ident(s) {
	map { 
		map{$_->destroy()} Audio::Nama::EffectChain::find( user => 1, name => $_);
	} @{ $item{'ident(s)'} };
	1;
}
find_effect_chains: _find_effect_chains ident(s?) 
{
	my @args;
	push @args, @{ $item{'ident(s?)'} } if $item{'ident(s?)'};
	Audio::Nama::pager(map{$_->dump} Audio::Nama::EffectChain::find(@args));
}
find_user_effect_chains: _find_user_effect_chains ident(s?)
{
	my @args = ('user' , 1);
	push @args, @{ $item{'ident(s)'} } if $item{'ident(s)'};
	(scalar @args) % 2 == 0 
		or Audio::Nama::throw("odd number of arguments\n@args\n"), return 0;
	Audio::Nama::pager( map{ $_->summary} Audio::Nama::EffectChain::find(@args)  );
	1;
}
bypass_effects:   _bypass_effects op_id(s) { 
	my $arr_ref = $item{'op_id(s)'};
	return unless (ref $arr_ref) =~ /ARRAY/  and scalar @{$arr_ref};
	my @illegal = grep { ! Audio::Nama::fxn($_) } @$arr_ref;
	Audio::Nama::throw("@illegal: non-existing effect(s), skipping."), return 0 if @illegal;
 	Audio::Nama::pager( "track ",$Audio::Nama::this_track->name,", bypassing effects:");
	Audio::Nama::pager( Audio::Nama::named_effects_list(@$arr_ref));
	Audio::Nama::bypass_effects($Audio::Nama::this_track,@$arr_ref);
	Audio::Nama::set_current_op($arr_ref->[0]) if scalar @$arr_ref == 1;
}
bypass_effects: _bypass_effects 'all' { 
	Audio::Nama::pager( "track ",$Audio::Nama::this_track->name,", bypassing all effects (except vol/pan)");
	Audio::Nama::bypass_effects($Audio::Nama::this_track, $Audio::Nama::this_track->fancy_ops)
		if $Audio::Nama::this_track->fancy_ops;
	1; 
}
bypass_effects: _bypass_effects { 
	Audio::Nama::throw("current effect is undefined, skipping"), return 1 if ! Audio::Nama::this_op();
 	Audio::Nama::pager( "track ",$Audio::Nama::this_track->name,", bypassing effects:"); 
	Audio::Nama::pager( Audio::Nama::named_effects_list(Audio::Nama::this_op()));
 	Audio::Nama::bypass_effects($Audio::Nama::this_track, Audio::Nama::this_op());  
 	1; 
}
bring_back_effects:   _bring_back_effects end { 
	Audio::Nama::pager("current effect is undefined, skipping"), return 1 if ! Audio::Nama::this_op();
	Audio::Nama::pager( "restoring effects:");
	Audio::Nama::pager( Audio::Nama::named_effects_list(Audio::Nama::this_op()));
	Audio::Nama::restore_effects( $Audio::Nama::this_track, Audio::Nama::this_op());
}
bring_back_effects:   _bring_back_effects op_id(s) { 
	my $arr_ref = $item{'op_id(s)'};
	return unless (ref $arr_ref) =~ /ARRAY/  and scalar @{$arr_ref};
	my @illegal = grep { ! Audio::Nama::fxn($_) } @$arr_ref;
	Audio::Nama::throw("@illegal: non-existing effect(s), aborting."), return 0 if @illegal;
	Audio::Nama::pager( "restoring effects:");
	Audio::Nama::pager( Audio::Nama::named_effects_list(@$arr_ref));
	Audio::Nama::restore_effects($Audio::Nama::this_track,@$arr_ref);
	Audio::Nama::set_current_op($arr_ref->[0]) if scalar @$arr_ref == 1;
}
bring_back_effects:   _bring_back_effects 'all' { 
	Audio::Nama::pager( "restoring all effects");
	Audio::Nama::restore_effects( $Audio::Nama::this_track, $Audio::Nama::this_track->fancy_ops);
}
fxc_val: shellish
this_track_op_id: op_id(s) { 
	my %ops = map{ $_ => 1 } @{$Audio::Nama::this_track->ops};
	my @ids = @{$item{'op_id(s)'}};
	my @belonging 	= grep {   $ops{$_} } @ids;
	my @alien 		= grep { ! $ops{$_} } @ids;
	@alien and Audio::Nama::pager("@alien: don't belong to track ",$Audio::Nama::this_track->name, "skipping."); 
	@belonging	
}
bunch_name: ident { 
	Audio::Nama::is_bunch($item{ident}) or Audio::Nama::bunch_tracks($item{ident})
		or Audio::Nama::throw("$item{ident}: no such bunch name."), return; 
	$item{ident};
}
effect_profile_name: ident
existing_effect_profile_name: ident {
	Audio::Nama::pager("$item{ident}: no such effect profile"), return
		unless Audio::Nama::EffectChain::find(profile => $item{ident});
	$item{ident}
}
new_effect_profile: _new_effect_profile bunch_name effect_profile_name {
	Audio::Nama::new_effect_profile($item{bunch_name}, $item{effect_profile_name}); 1 }
destroy_effect_profile: _destroy_effect_profile existing_effect_profile_name {
	Audio::Nama::delete_effect_profile($item{existing_effect_profile_name}); 1 }
apply_effect_profile: _apply_effect_profile existing_effect_profile_name {
	Audio::Nama::apply_effect_profile($item{effect_profile_name}); 1 }
list_effect_profiles: _list_effect_profiles {
	my %profiles;
	map{ $profiles{$_->profile}++ } Audio::Nama::EffectChain::find(profile => 1);
	my @output = keys %profiles;
	if( @output )
	{ Audio::Nama::pager( join " ","Effect Profiles available:", @output) }
	else { Audio::Nama::throw("no match") }
	1;
}
show_effect_profiles: _show_effect_profiles ident(?) {
	my $name;
	$name = $item{'ident(?)'}->[-1] if $item{'ident(?)'};
	$name ||= 1;
	my %profiles;
	map{ $profiles{$_->profile}++ } Audio::Nama::EffectChain::find(profile => $name);
	my @names = keys %profiles;
	my @output;
	for $name (@names) {
		push @output, "\nprofile name: $name\n";
		map { push @output, $_->summary } Audio::Nama::EffectChain::find(profile => $name)
	}
	if( @output )
	{ Audio::Nama::pager( @output); }
	else { Audio::Nama::throw("no match") }
	1;
}
full_effect_profiles: _full_effect_profiles ident(?) {
	my $name;
	$name = $item{'ident(?)'}->[-1] if $item{'ident(?)'};
	$name ||= 1;
	my @output = map{ $_->dump } Audio::Nama::EffectChain::find(profile => $name )  ;
	if( @output )
	{ Audio::Nama::pager( @output); }
	else { Audio::Nama::throw("no match") }
	1;
}
do_script: _do_script shellish { Audio::Nama::do_script($item{shellish});1}
scan: _scan { Audio::Nama::pager( "scanning ", Audio::Nama::this_wav_dir()); Audio::Nama::restart_wav_memoize() }
add_fade: _add_fade in_or_out mark1 duration(?)
{ 	Audio::Nama::Fade->new(  type => $item{in_or_out},
					mark1 => $item{mark1},
					duration => $item{'duration(?)'}->[0] 
								|| $Audio::Nama::config->{engine_fade_default_length}, 
					relation => 'fade_from_mark',
					track => $Audio::Nama::this_track->name,
	); 
	Audio::Nama::request_setup();
}
add_fade: _add_fade in_or_out duration(?) mark1 
{ 	Audio::Nama::Fade->new(  type => $item{in_or_out},
					mark1 => $item{mark1},
					duration => $item{'duration(?)'}->[0] 
								|| $Audio::Nama::config->{engine_fade_default_length}, 
					track => $Audio::Nama::this_track->name,
					relation => 'fade_to_mark',
	);
	Audio::Nama::request_setup();
}
add_fade: _add_fade in_or_out mark1 mark2
{ 	Audio::Nama::Fade->new(  type => $item{in_or_out},
					mark1 => $item{mark1},
					mark2 => $item{mark2},
					track => $Audio::Nama::this_track->name,
	);
	Audio::Nama::request_setup();
}
add_fade: _add_fade in_or_out time1 time2 
{ 	
	my $mark1 = Audio::Nama::Mark->new( 
		name => join('_',$Audio::Nama::this_track->name, 'fade', Audio::Nama::Mark::next_id()),
		time => $item{time1}
	);
	my $mark2 = Audio::Nama::Mark->new( 
		name => join('_',$Audio::Nama::this_track->name, 'fade', Audio::Nama::Mark::next_id()),
		time => $item{time2}
	);
	Audio::Nama::Fade->new(  type => $item{in_or_out},
					mark1 => $mark1->name,
					mark2 => $mark2->name,
					track => $Audio::Nama::this_track->name,
	);
	Audio::Nama::request_setup();
}
time1: value
time2: value
in_or_out: 'in' | 'out'
duration: value
mark1: markname
mark2: markname
remove_fade: _remove_fade fade_index(s) { 
	my @i = @{ $item{'fade_index(s)'} };
	Audio::Nama::remove_fade($_) for (@i);
	Audio::Nama::request_setup();
	1
}
fade_index: dd 
list_fade: _list_fade {  Audio::Nama::pager(join "\n",
		map{ s/^---//; s/...\s$//; $_} map{$_->dump}
		sort{$a->n <=> $b->n} values %Audio::Nama::Fade::by_index) }
add_comment: _add_comment text { 
 	Audio::Nama::pager( $Audio::Nama::this_track->name, ": comment: $item{text}"); 
 	$Audio::Nama::project->{track_comments}->{$Audio::Nama::this_track->name} = $item{text};
 	1;
}
remove_comment: _remove_comment {
 	Audio::Nama::pager( $Audio::Nama::this_track->name, ": comment removed");
 	delete $Audio::Nama::project->{track_comments}->{$Audio::Nama::this_track->name};
 	1;
}
show_comment: _show_comment {
	map{ Audio::Nama::pager( "(",$_->group,") ", $_->name, ": ", $_->comment) } $Audio::Nama::this_track;
	1;
}
show_comments: _show_comments {
	map{ Audio::Nama::pager( "(",$_->group,") ", $_->name, ": ", $_->comment) } Audio::Nama::all_tracks();
	1;
}
add_version_comment: _add_version_comment dd(?) text {
	my $t = $Audio::Nama::this_track;
	my $v = $item{'dd(?)'}->[0] // $t->monitor_version // return 1;
	Audio::Nama::pager( $t->add_version_comment($v,$item{text})); 
}	
remove_version_comment: _remove_version_comment dd {
	my $t = $Audio::Nama::this_track;
	Audio::Nama::pager( $t->remove_version_comment($item{dd})); 1
}
show_version_comment: _show_version_comment dd(s?) {
	my $t = $Audio::Nama::this_track;
	my @v = @{$item{'dd(s?)'}};
	if(!@v){ @v = $t->monitor_version}
	@v or return 1;
	$t->show_version_comments(@v);
	 1;
}
show_version_comments_all: _show_version_comments_all {
	my $t = $Audio::Nama::this_track;
	my @v = @{$t->versions};
	$t->show_version_comments(@v); 1;
}
set_system_version_comment: _set_system_version_comment dd text {
	Audio::Nama::pager( Audio::Nama::set_system_version_comment($Audio::Nama::this_track,@item{qw(dd text)}));1;
}
midish_command: _midish_command text {
	Audio::Nama::midish_command( $item{text} ); 1
}
midish_mode_on: _midish_mode_on { 
	Audio::Nama::pager("Setting midish terminal mode!! Return with 'midish_mode_off'.");
	$Audio::Nama::mode->{midish_terminal}++;
}
midish_mode_off: _midish_mode_off { 
	Audio::Nama::pager("Releasing midish terminal mode. Sync is not enabled.");
	undef $Audio::Nama::mode->{midish_terminal};
	undef $Audio::Nama::mode->{midish_transport_sync};
	1;
}
midish_mode_off_ready_to_play: _midish_mode_off_ready_to_play { 
	Audio::Nama::pager("Releasing midish terminal mode.
Will sync playback with Ecasound."); 
	undef $Audio::Nama::mode->{midish_terminal} ;
	$Audio::Nama::mode->{midish_transport_sync} = 'play';
	1;
}
midish_mode_off_ready_to_record: _midish_mode_off_ready_to_record { 
	Audio::Nama::pager("Releasing midish terminal mode. 
Will sync record with Ecasound.");
	undef $Audio::Nama::mode->{midish_terminal} ;
	$Audio::Nama::mode->{midish_transport_sync} = 'record';
	1;
}
new_edit: _new_edit {
	Audio::Nama::new_edit();
	1;
}
set_edit_points: _set_edit_points { Audio::Nama::set_edit_points(); 1 }
list_edits: _list_edits { Audio::Nama::list_edits(); 1}
destroy_edit: _destroy_edit { Audio::Nama::destroy_edit(); 1}
select_edit: _select_edit dd { Audio::Nama::select_edit($item{dd}); 1}
preview_edit_in: _preview_edit_in { Audio::Nama::edit_action($item[0]); 1}
preview_edit_out: _preview_edit_out { Audio::Nama::edit_action($item[0]); 1}
play_edit: _play_edit { Audio::Nama::edit_action($item[0]); 1}
record_edit: _record_edit { Audio::Nama::edit_action($item[0]); 1}
edit_track: _edit_track { 
	Audio::Nama::select_edit_track('edit_track'); 1}
host_track_alias: _host_track_alias {
	Audio::Nama::select_edit_track('host_alias_track'); 1}
host_track: _host_track { 
	Audio::Nama::select_edit_track('host'); 1}
version_mix_track: _version_mix_track {
	Audio::Nama::select_edit_track('version_mix'); 1}
play_start_mark: _play_start_mark {
	my $mark = $Audio::Nama::this_edit->play_start_mark;
	$mark->jump_here; 1;
}
rec_start_mark: _rec_start_mark {
	$Audio::Nama::this_edit->rec_start_mark->jump_here; 1;
}
rec_end_mark: _rec_end_mark {
	$Audio::Nama::this_edit->rec_end_mark->jump_here; 1;
}
set_play_start_mark: _set_play_start_mark {
	$Audio::Nama::setup->{edit_points}->[0] = Audio::Nama::eval_iam('getpos'); 1}
set_rec_start_mark: _set_rec_start_mark {
	$Audio::Nama::setup->{edit_points}->[1] = Audio::Nama::eval_iam('getpos'); 1}
set_rec_end_mark: _set_rec_end_mark {
	$Audio::Nama::setup->{edit_points}->[2] = Audio::Nama::eval_iam('getpos'); 1}
end_edit_mode: _end_edit_mode { Audio::Nama::end_edit_mode(); 1;}
disable_edits: _disable_edits { Audio::Nama::disable_edits();1 }
merge_edits: _merge_edits { Audio::Nama::merge_edits(); 1; }
explode_track: _explode_track {
	Audio::Nama::explode_track($Audio::Nama::this_track)
}
promote_version_to_track: _promote_version_to_track version {
	my $v = $item{version};
	my $t = $Audio::Nama::this_track;
	$t->versions->[$v] or Audio::Nama::pager($t->name,": version $v does not exist."),
		return;
	Audio::Nama::VersionTrack->new(
		name 	=> $t->name.":$v",
		version => $v, 
		target  => $t->name,
		rw		=> Audio::Nama::PLAY,
		group   => $t->group,
	);
}
version: dd
read_user_customizations: _read_user_customizations {
	Audio::Nama::setup_user_customization(); 1
}
limit_run_time: _limit_run_time sign(?) dd { 
	my $sign = $item{'sign(?)'}->[-1]; 
	$Audio::Nama::setup->{runtime_limit} = $sign
		? eval "$Audio::Nama::setup->{audio_length} $sign $item{dd}"
		: $item{dd};
	Audio::Nama::pager( "Run time limit: ", Audio::Nama::heuristic_time($Audio::Nama::setup->{runtime_limit})); 1;
}
limit_run_time_off: _limit_run_time_off { 
	Audio::Nama::pager( "Run timer disabled");
	Audio::Nama::disable_length_timer();
	1;
}
offset_run: _offset_run markname {
	Audio::Nama::set_offset_run_mark( $item{markname} ); 1
}
offset_run_off: _offset_run_off {
	Audio::Nama::pager( "no run offset.");
	Audio::Nama::disable_offset_run_mode(); 
}
view_waveform: _view_waveform { 
	my $viewer = 'mhwaveedit';
	if( `which $viewer` =~ m/\S/){ 
		my $cmd = join " ",
			$viewer,
			"--driver",
			$Audio::Nama::jack->{jackd_running} ? "jack" : "alsa",
			$Audio::Nama::this_track->full_path,
			"&";
		system($cmd) 
	}
	else { Audio::Nama::throw("Mhwaveedit not found. No waveform viewer is available.") }
}
edit_waveform: _edit_waveform { 
	if ( `which audacity` =~ m/\S/ ){  
		my $cmd = join " ",
			'audacity',
			$Audio::Nama::this_track->full_path,
			"&";
		my $old_pwd = Audio::Nama::getcwd();		
		chdir Audio::Nama::this_wav_dir();
		system($cmd);
		chdir $old_pwd;
	}
	else { Audio::Nama::throw("Audacity not found. No waveform editor available.") }
	1;
}
rerecord: _rerecord { 
		Audio::Nama::pager(
			scalar @{$Audio::Nama::setup->{_last_rec_tracks}} 
				?  "Toggling previous recording tracks to REC"
				:  "No tracks in REC list. Skipping."
		);
		map{ $_->set(rw => Audio::Nama::REC) } @{$Audio::Nama::setup->{_last_rec_tracks}}; 
		Audio::Nama::restore_preview_mode();
		1;
}
show_track_latency: _show_track_latency {
	my $node = $Audio::Nama::setup->{latency}->{track}->{$Audio::Nama::this_track->name};
	Audio::Nama::pager( Audio::Nama::json_out($node)) if $node;
	1;
}
show_latency_all: _show_latency_all { 
	Audio::Nama::pager( Audio::Nama::json_out($Audio::Nama::setup->{latency})) if $Audio::Nama::setup->{latency};
	1;
}
analyze_level: _analyze_level { Audio::Nama::check_level($Audio::Nama::this_track);1 }
git: _git shellcode stopper { 
Audio::Nama::pager(map {$_.="\n"} $Audio::Nama::project->{repo}->run( split " ", $item{shellcode})) 
}
edit_rec_setup_hook: _edit_rec_setup_hook { 
	system("$ENV{EDITOR} ".$Audio::Nama::this_track->rec_setup_script() );
	chmod 0755, $Audio::Nama::this_track->rec_setup_script();
	1
}
edit_rec_cleanup_hook: _edit_rec_cleanup_hook { 
	system("$ENV{EDITOR} ".$Audio::Nama::this_track->rec_cleanup_script() );
	chmod 0755, $Audio::Nama::this_track->rec_cleanup_script();
	1
}
remove_fader_effect: _remove_fader_effect fader_role {
	Audio::Nama::remove_fader_effect($Audio::Nama::this_track, $item{fader_role});
	1
}
fader_role: 'vol'|'pan'|'fader'
hotkeys: _hotkeys { Audio::Nama::setup_hotkeys()}
hotkeys_always: _hotkeys_always { $Audio::Nama::config->{hotkeys_always}++; Audio::Nama::setup_hotkeys(); }
hotkeys_off: _hotkeys_off { undef $Audio::Nama::config->{hotkeys_always}; 1 }
hotkeys_list: _hotkeys_list { Audio::Nama::list_hotkeys() ; 1 } 
select_sequence: _select_sequence existing_sequence_name { 
	$Audio::Nama::this_sequence = $Audio::Nama::bn{$item{existing_sequence_name}}
} 
existing_sequence_name: ident { 
		my $buslike = $Audio::Nama::bn{$item{ident}};
		$return = $item{ident} if (ref $buslike) =~ /Sequence/
}
convert_to_sequence: _convert_to_sequence {
	my $sequence_name = $Audio::Nama::this_track->name;
	Audio::Nama::process_command("nsq $sequence_name");
	$Audio::Nama::this_sequence->new_clip($Audio::Nama::this_track);
	1
}
merge_sequence: _merge_sequence { cache_track($Audio::Nama::tn{$Audio::Nama::this_sequence->name}); 1 }
new_sequence: _new_sequence new_sequence_name track_identifier(s?) {
	Audio::Nama::new_sequence( name   => $item{new_sequence_name},
					tracks => $item{'track_identifier(s?)'} || []
	);
	1
}
new_sequence_name: ident { $return = 
	$Audio::Nama::bn{$item{ident}}
		? do { Audio::Nama::pager("$item{ident}: name already in use\n"), undef}
		: $item{ident} 
}
track_identifier: tid {  
	my $tid = $Audio::Nama::tn{$item{tid}} || $Audio::Nama::ti{$item{tid}} ;
	if ($tid) { $tid }
	else 
	{ 	Audio::Nama::throw("$item{tid}: track name or index not found.\n"); 
		undef
	}
}
tid: ident
list_sequences: _list_sequences { 
	Audio::Nama::pager( map {Audio::Nama::json_out($_->as_hash)} 
			grep {$_->{class} =~ /Sequence/} Audio::Nama::Bus::all() );
}
show_sequence: _show_sequence { Audio::Nama::pager($Audio::Nama::this_sequence->list_output) }
append_to_sequence: _append_to_sequence track_identifier(s?) { 
	my $seq = $Audio::Nama::this_sequence;
	my $items = $item{'track_identifier(s?)'} || [$Audio::Nama::this_track];
	map { my $clip = $seq->new_clip($_); $seq->append_item($clip) } @$items; 
	1;
}
insert_in_sequence: _insert_in_sequence position track_identifier(s) {
	my $seq = $Audio::Nama::this_sequence;
	my $items = $item{'track_identifier(s)'};
	my $position = $item{position};
	for ( reverse map{ $seq->new_clip($_) } @$items ){ $seq->insert_item($_,$position) }
}
remove_from_sequence: _remove_from_sequence position(s) {
	my $seq = $Audio::Nama::this_sequence;
	my @positions = sort { $a <=> $b } @{ $item{'position(s)'}};
	$seq->verify_item($_) 
		?  $seq->delete_item($_) 
		: Audio::Nama::throw("skipping index $_: out of bounds")
	for reverse @positions
}
delete_sequence: _delete_sequence existing_sequence_name {
	$Audio::Nama::bn{$item{existing_sequence_name}}->remove
}
position: dd { $Audio::Nama::this_sequence->verify_item($item{dd}) and $item{dd} }
add_spacer: _add_spacer value position {
	$Audio::Nama::this_sequence->new_spacer(
		duration => $item{value},
		position => $item{position},
		hidden   => 1,
	);
	Audio::Nama::request_setup();
	1
}
add_spacer: _add_spacer value { 
	$Audio::Nama::this_sequence->new_spacer(
		duration => $item{value},
        hidden   => 1,
	);
	Audio::Nama::request_setup();
	1
}
snip: _snip track_identifier mark_pair(s) { 
	my $track = $item{track_identifier};
	my @pairs = $item{'mark_pair(s)'};
	my @list = map{ @$_ } @pairs;	
	@list = (0, @list, $track->length);
	@pairs = ();
	while ( scalar @list ){ push @pairs, [splice( @list, 0, 2)] }
	Audio::Nama::compose_sequence($track->name, $track, \@pairs);
}
compose: _compose ident track_identifier mark_pair(s) {
	Audio::Nama::compose_sequence(@item{qw/ident track_identifier mark_pair(s)/});
}
mark_pair: mark1 mark2 { 
	my @marks = map{ $Audio::Nama::mn{$_}} @item{qw(mark1 mark2)};
 	Audio::Nama::throw(join" ",(map{$_->name} @marks), 
		": pair must be ascending in time"), return undef
 	 	if not( $marks[0]->time < $marks[1]->time );
 	\@marks
}
mark1: ident { $Audio::Nama::mn{$item{ident}} }
mark2: mark1
snip: _snip new_sequence_name mark_pair(s) {}
rename_track: _rename_track existing_track_name new_track_name { 
	Audio::Nama::rename_track(
		@item{qw(existing_track_name new_track_name)}, 
		$Audio::Nama::file->git_state_store, 
		Audio::Nama::this_wav_dir()
	);
}
undo: _undo { Audio::Nama::undo() }
redo: _redo { Audio::Nama::redo() }
show_head_commit: _show_head_commit { Audio::Nama::show_head_commit() }
eager: _eager on_or_off { $Audio::Nama::mode->{eager} = $item{on_or_off} =~ /[1n]/ ? 1 : 0 }
on_or_off: 'on' | '1' | 'off' | '0'
new_engine: _new_engine ident port { Audio::Nama::Engine->new(name => $item{ident}, port => $item{port}) }
port: dd
select_engine: _select_engine ident {
	my $new_choice = $Audio::Nama::Engine::by_name{$item{ident}};
	$Audio::Nama::this_engine = $new_choice if defined $new_choice;
	Audio::Nama::pager("Current engine is ".$Audio::Nama::this_engine->name)
}
set_track_engine_group: _set_track_engine_group ident {
	$Audio::Nama::this_track->set(engine_group => $item{ident});
	Audio::Nama::pager($Audio::Nama::this_track->name. ": engine group set to $item{ident}");
}
set_bus_engine_group: _set_bus_engine_group ident {
	$Audio::Nama::bn{$Audio::Nama::this_bus}->set(engine_group => $item{ident});
 	Audio::Nama::pager("$Audio::Nama::this_bus: bus engine group set to $item{ident}");
}
select_submix: _select_submix existing_bus_name { 
	$Audio::Nama::this_user = $Audio::Nama::bn{$item{existing_bus_name}}
}
trim_submix: _trim_submix effect parameter sign(?) value { 
	my $real_track = join '_', $Audio::Nama::this_user->name, $Audio::Nama::this_track->name;
	Audio::Nama::pager("real track: $real_track\n");
	my $FX = $Audio::Nama::tn{$real_track}->first_effect_of_type(Audio::Nama::full_effect_code($item{effect}));
 	Audio::Nama::modify_effect($FX->id, $item{parameter}, @{$item{'sign(?)'}}, $item{value});
}
set_effect_name: _set_effect_name ident { Audio::Nama::this_op_o->set_name($item{ident}); 1}
remove_effect_name: _remove_effect_name { Audio::Nama::this_op_o->set_name(); 1 			  }
set_effect_surname: _set_effect_surname ident { Audio::Nama::this_op_o->set_surname($item{ident}); 1}
remove_effect_surname: _remove_effect_surname { Audio::Nama::this_op_o()->set_surname(); 1} 
select_track: _select_track track_spec

command: help
command: help_effect
command: find_effect
command: exit
command: memoize
command: unmemoize
command: stop
command: start
command: getpos
command: setpos
command: forward
command: rewind
command: to_start
command: to_end
command: ecasound_start
command: ecasound_stop
command: restart_ecasound
command: preview
command: doodle
command: mixdown
command: mixplay
command: mixoff
command: automix
command: master_on
command: master_off
command: add_track
command: add_tracks
command: add_midi_track
command: link_track
command: import_audio
command: set_track
command: record
command: play
command: mon
command: off
command: source
command: send
command: remove_send
command: stereo
command: mono
command: set_version
command: destroy_current_wav
command: list_versions
command: vol
command: mute
command: unmute
command: unity
command: solo
command: nosolo
command: all
command: pan
command: pan_right
command: pan_left
command: pan_center
command: pan_back
command: show_tracks
command: show_tracks_all
command: show_bus_tracks
command: show_track
command: show_mode
command: show_track_latency
command: show_latency_all
command: set_region
command: add_region
command: remove_region
command: shift_track
command: unshift_track
command: modifiers
command: nomodifiers
command: normalize
command: fixdc
command: autofix_tracks
command: remove_track
command: bus_mon
command: bus_off
command: bus_version
command: add_bunch
command: list_bunches
command: remove_bunch
command: add_to_bunch
command: commit
command: tag
command: branch
command: list_branches
command: new_branch
command: save_state
command: get_state
command: list_projects
command: new_project
command: load_project
command: project_name
command: new_project_template
command: use_project_template
command: list_project_templates
command: destroy_project_template
command: generate
command: arm
command: arm_start
command: connect
command: disconnect
command: show_chain_setup
command: loop
command: noloop
command: add_controller
command: add_effect
command: add_effect_last
command: add_effect_first
command: add_effect_before
command: modify_effect
command: remove_effect
command: position_effect
command: show_effect
command: dump_effect
command: list_effects
command: hotkeys
command: hotkeys_always
command: hotkeys_off
command: hotkeys_list
command: add_insert
command: set_insert_wetness
command: remove_insert
command: ctrl_register
command: preset_register
command: ladspa_register
command: list_marks
command: to_mark
command: add_mark
command: remove_mark
command: next_mark
command: previous_mark
command: name_mark
command: modify_mark
command: engine_status
command: dump_track
command: dump_group
command: dump_all
command: dump_io
command: list_history
command: add_submix_cooked
command: add_submix_raw
command: add_bus
command: update_submix
command: remove_bus
command: list_buses
command: set_bus
command: overwrite_effect_chain
command: new_effect_chain
command: delete_effect_chain
command: find_effect_chains
command: find_user_effect_chains
command: bypass_effects
command: bring_back_effects
command: new_effect_profile
command: apply_effect_profile
command: destroy_effect_profile
command: list_effect_profiles
command: show_effect_profiles
command: full_effect_profiles
command: cache_track
command: uncache_track
command: do_script
command: scan
command: add_fade
command: remove_fade
command: list_fade
command: add_comment
command: remove_comment
command: show_comment
command: show_comments
command: add_version_comment
command: remove_version_comment
command: show_version_comment
command: show_version_comments_all
command: set_system_version_comment
command: midish_command
command: midish_mode_on
command: midish_mode_off
command: midish_mode_off_ready_to_play
command: midish_mode_off_ready_to_record
command: new_edit
command: set_edit_points
command: list_edits
command: select_edit
command: end_edit_mode
command: destroy_edit
command: preview_edit_in
command: preview_edit_out
command: play_edit
command: record_edit
command: edit_track
command: host_track_alias
command: host_track
command: version_mix_track
command: play_start_mark
command: rec_start_mark
command: rec_end_mark
command: set_play_start_mark
command: set_rec_start_mark
command: set_rec_end_mark
command: disable_edits
command: merge_edits
command: explode_track
command: move_to_bus
command: promote_version_to_track
command: read_user_customizations
command: limit_run_time
command: limit_run_time_off
command: offset_run
command: offset_run_off
command: view_waveform
command: edit_waveform
command: rerecord
command: analyze_level
command: for
command: git
command: edit_rec_setup_hook
command: edit_rec_cleanup_hook
command: remove_fader_effect
command: rename_track
command: new_sequence
command: select_sequence
command: list_sequences
command: show_sequence
command: append_to_sequence
command: insert_in_sequence
command: remove_from_sequence
command: delete_sequence
command: add_spacer
command: convert_to_sequence
command: merge_sequence
command: snip
command: compose
command: undo
command: redo
command: show_head_commit
command: eager
command: new_engine
command: select_engine
command: set_track_engine_group
command: set_bus_engine_group
command: select_submix
command: trim_submix
command: nickname_effect
command: delete_nickname_definition
command: remove_nickname
command: list_nickname_definitions
command: set_effect_name
command: set_effect_surname
command: remove_effect_name
command: remove_effect_surname
command: select_track
_help: /help\b/ | /h\b/ { "help" } 
_help_effect: /help_effect\b/ | /hfx\b/ | /he\b/ { "help_effect" } 
_find_effect: /find_effect\b/ | /ffx\b/ | /fe\b/ { "find_effect" } 
_exit: /exit\b/ | /quit\b/ | /q\b/ { "exit" } 
_memoize: /memoize\b/ { "memoize" } 
_unmemoize: /unmemoize\b/ { "unmemoize" } 
_stop: /stop\b/ | /s\b/ { "stop" } 
_start: /start\b/ | /t\b/ { "start" } 
_getpos: /getpos\b/ | /gp\b/ { "getpos" } 
_setpos: /setpos\b/ | /sp\b/ { "setpos" } 
_forward: /forward\b/ | /fw\b/ { "forward" } 
_rewind: /rewind\b/ | /rw\b/ { "rewind" } 
_to_start: /to_start\b/ | /beg\b/ { "to_start" } 
_to_end: /to_end\b/ | /end\b/ { "to_end" } 
_ecasound_start: /ecasound_start\b/ { "ecasound_start" } 
_ecasound_stop: /ecasound_stop\b/ { "ecasound_stop" } 
_restart_ecasound: /restart_ecasound\b/ { "restart_ecasound" } 
_preview: /preview\b/ | /song\b/ { "preview" } 
_doodle: /doodle\b/ | /live\b/ { "doodle" } 
_mixdown: /mixdown\b/ | /mxd\b/ { "mixdown" } 
_mixplay: /mixplay\b/ | /mxp\b/ { "mixplay" } 
_mixoff: /mixoff\b/ | /mxo\b/ { "mixoff" } 
_automix: /automix\b/ { "automix" } 
_master_on: /master_on\b/ | /mr\b/ { "master_on" } 
_master_off: /master_off\b/ | /mro\b/ { "master_off" } 
_add_track: /add_track\b/ | /add\b/ | /new\b/ { "add_track" } 
_add_tracks: /add_tracks\b/ { "add_tracks" } 
_add_midi_track: /add_midi_track\b/ | /amt\b/ { "add_midi_track" } 
_link_track: /link_track\b/ | /link\b/ { "link_track" } 
_import_audio: /import_audio\b/ | /import\b/ { "import_audio" } 
_set_track: /set_track\b/ { "set_track" } 
_record: /record\b/ | /rec\b/ { "record" } 
_play: /play\b/ { "play" } 
_mon: /mon\b/ { "mon" } 
_off: /off\b/ { "off" } 
_source: /source\b/ | /src\b/ | /r\b/ { "source" } 
_send: /send\b/ | /aux\b/ { "send" } 
_remove_send: /remove_send\b/ | /nosend\b/ | /noaux\b/ { "remove_send" } 
_stereo: /stereo\b/ { "stereo" } 
_mono: /mono\b/ { "mono" } 
_set_version: /set_version\b/ | /version\b/ | /ver\b/ { "set_version" } 
_destroy_current_wav: /destroy_current_wav\b/ { "destroy_current_wav" } 
_list_versions: /list_versions\b/ | /lver\b/ { "list_versions" } 
_vol: /vol\b/ | /v\b/ { "vol" } 
_mute: /mute\b/ | /c\b/ | /cut\b/ { "mute" } 
_unmute: /unmute\b/ | /nomute\b/ | /C\b/ | /uncut\b/ { "unmute" } 
_unity: /unity\b/ { "unity" } 
_solo: /solo\b/ | /sl\b/ { "solo" } 
_nosolo: /nosolo\b/ | /nsl\b/ { "nosolo" } 
_all: /all\b/ { "all" } 
_pan: /pan\b/ | /p\b/ { "pan" } 
_pan_right: /pan_right\b/ | /pr\b/ { "pan_right" } 
_pan_left: /pan_left\b/ | /pl\b/ { "pan_left" } 
_pan_center: /pan_center\b/ | /pc\b/ { "pan_center" } 
_pan_back: /pan_back\b/ | /pb\b/ { "pan_back" } 
_show_tracks: /show_tracks\b/ | /lt\b/ | /show\b/ { "show_tracks" } 
_show_tracks_all: /show_tracks_all\b/ | /sha\b/ | /showa\b/ { "show_tracks_all" } 
_show_bus_tracks: /show_bus_tracks\b/ | /ltb\b/ | /showb\b/ { "show_bus_tracks" } 
_show_track: /show_track\b/ | /sh\b/ | /-fart\b/ { "show_track" } 
_show_mode: /show_mode\b/ | /shm\b/ { "show_mode" } 
_show_track_latency: /show_track_latency\b/ | /shl\b/ { "show_track_latency" } 
_show_latency_all: /show_latency_all\b/ | /shla\b/ { "show_latency_all" } 
_set_region: /set_region\b/ | /srg\b/ { "set_region" } 
_add_region: /add_region\b/ { "add_region" } 
_remove_region: /remove_region\b/ | /rrg\b/ { "remove_region" } 
_shift_track: /shift_track\b/ | /shift\b/ | /playat\b/ | /pat\b/ { "shift_track" } 
_unshift_track: /unshift_track\b/ | /unshift\b/ { "unshift_track" } 
_modifiers: /modifiers\b/ | /mods\b/ | /mod\b/ { "modifiers" } 
_nomodifiers: /nomodifiers\b/ | /nomods\b/ | /nomod\b/ { "nomodifiers" } 
_normalize: /normalize\b/ | /ecanormalize\b/ { "normalize" } 
_fixdc: /fixdc\b/ | /ecafixdc\b/ { "fixdc" } 
_autofix_tracks: /autofix_tracks\b/ | /autofix\b/ { "autofix_tracks" } 
_remove_track: /remove_track\b/ { "remove_track" } 
_bus_mon: /bus_mon\b/ | /bmon\b/ { "bus_mon" } 
_bus_off: /bus_off\b/ | /boff\b/ { "bus_off" } 
_bus_version: /bus_version\b/ | /bver\b/ | /gver\b/ { "bus_version" } 
_add_bunch: /add_bunch\b/ | /abn\b/ { "add_bunch" } 
_list_bunches: /list_bunches\b/ | /lbn\b/ { "list_bunches" } 
_remove_bunch: /remove_bunch\b/ | /rbn\b/ { "remove_bunch" } 
_add_to_bunch: /add_to_bunch\b/ | /atbn\b/ { "add_to_bunch" } 
_commit: /commit\b/ | /ci\b/ { "commit" } 
_tag: /tag\b/ { "tag" } 
_branch: /branch\b/ | /br\b/ { "branch" } 
_list_branches: /list_branches\b/ | /lb\b/ | /lbr\b/ { "list_branches" } 
_new_branch: /new_branch\b/ | /nbr\b/ { "new_branch" } 
_save_state: /save_state\b/ | /keep\b/ | /save\b/ { "save_state" } 
_get_state: /get_state\b/ | /get\b/ | /recall\b/ | /retrieve\b/ { "get_state" } 
_list_projects: /list_projects\b/ | /lp\b/ { "list_projects" } 
_new_project: /new_project\b/ | /create\b/ { "new_project" } 
_load_project: /load_project\b/ | /load\b/ { "load_project" } 
_project_name: /project_name\b/ | /project\b/ | /name\b/ { "project_name" } 
_new_project_template: /new_project_template\b/ | /npt\b/ { "new_project_template" } 
_use_project_template: /use_project_template\b/ | /upt\b/ | /apt\b/ { "use_project_template" } 
_list_project_templates: /list_project_templates\b/ | /lpt\b/ { "list_project_templates" } 
_destroy_project_template: /destroy_project_template\b/ { "destroy_project_template" } 
_generate: /generate\b/ | /gen\b/ { "generate" } 
_arm: /arm\b/ { "arm" } 
_arm_start: /arm_start\b/ | /arms\b/ { "arm_start" } 
_connect: /connect\b/ | /con\b/ { "connect" } 
_disconnect: /disconnect\b/ | /dcon\b/ { "disconnect" } 
_show_chain_setup: /show_chain_setup\b/ | /chains\b/ { "show_chain_setup" } 
_loop: /loop\b/ | /l\b/ { "loop" } 
_noloop: /noloop\b/ | /nl\b/ { "noloop" } 
_add_controller: /add_controller\b/ | /acl\b/ { "add_controller" } 
_add_effect: /add_effect\b/ | /afx\b/ { "add_effect" } 
_add_effect_last: /add_effect_last\b/ | /afxl\b/ { "add_effect_last" } 
_add_effect_first: /add_effect_first\b/ | /afxf\b/ { "add_effect_first" } 
_add_effect_before: /add_effect_before\b/ | /afxb\b/ { "add_effect_before" } 
_modify_effect: /modify_effect\b/ | /mfx\b/ { "modify_effect" } 
_remove_effect: /remove_effect\b/ | /rfx\b/ { "remove_effect" } 
_position_effect: /position_effect\b/ | /pfx\b/ { "position_effect" } 
_show_effect: /show_effect\b/ | /sfx\b/ { "show_effect" } 
_dump_effect: /dump_effect\b/ | /dfx\b/ { "dump_effect" } 
_list_effects: /list_effects\b/ | /lfx\b/ { "list_effects" } 
_hotkeys: /hotkeys\b/ | /hk\b/ { "hotkeys" } 
_hotkeys_always: /hotkeys_always\b/ | /hka\b/ { "hotkeys_always" } 
_hotkeys_off: /hotkeys_off\b/ | /hko\b/ { "hotkeys_off" } 
_hotkeys_list: /hotkeys_list\b/ | /hkl\b/ | /lhk\b/ { "hotkeys_list" } 
_add_insert: /add_insert\b/ | /ain\b/ { "add_insert" } 
_set_insert_wetness: /set_insert_wetness\b/ | /wet\b/ { "set_insert_wetness" } 
_remove_insert: /remove_insert\b/ | /rin\b/ { "remove_insert" } 
_ctrl_register: /ctrl_register\b/ | /crg\b/ { "ctrl_register" } 
_preset_register: /preset_register\b/ | /prg\b/ { "preset_register" } 
_ladspa_register: /ladspa_register\b/ | /lrg\b/ { "ladspa_register" } 
_list_marks: /list_marks\b/ | /lmk\b/ | /lm\b/ { "list_marks" } 
_to_mark: /to_mark\b/ | /tmk\b/ | /tom\b/ { "to_mark" } 
_add_mark: /add_mark\b/ | /mark\b/ | /amk\b/ | /k\b/ { "add_mark" } 
_remove_mark: /remove_mark\b/ | /rmk\b/ { "remove_mark" } 
_next_mark: /next_mark\b/ | /nmk\b/ { "next_mark" } 
_previous_mark: /previous_mark\b/ | /pmk\b/ { "previous_mark" } 
_name_mark: /name_mark\b/ { "name_mark" } 
_modify_mark: /modify_mark\b/ | /move_mark\b/ | /mmk\b/ { "modify_mark" } 
_engine_status: /engine_status\b/ | /egs\b/ { "engine_status" } 
_dump_track: /dump_track\b/ | /dump\b/ { "dump_track" } 
_dump_group: /dump_group\b/ | /dumpg\b/ { "dump_group" } 
_dump_all: /dump_all\b/ | /dumpa\b/ { "dump_all" } 
_dump_io: /dump_io\b/ { "dump_io" } 
_list_history: /list_history\b/ | /lh\b/ { "list_history" } 
_add_submix_cooked: /add_submix_cooked\b/ { "add_submix_cooked" } 
_add_submix_raw: /add_submix_raw\b/ | /asr\b/ { "add_submix_raw" } 
_add_bus: /add_bus\b/ | /abs\b/ { "add_bus" } 
_update_submix: /update_submix\b/ | /usm\b/ { "update_submix" } 
_remove_bus: /remove_bus\b/ { "remove_bus" } 
_list_buses: /list_buses\b/ | /lbs\b/ { "list_buses" } 
_set_bus: /set_bus\b/ | /sbs\b/ { "set_bus" } 
_overwrite_effect_chain: /overwrite_effect_chain\b/ | /oec\b/ { "overwrite_effect_chain" } 
_new_effect_chain: /new_effect_chain\b/ | /nec\b/ { "new_effect_chain" } 
_delete_effect_chain: /delete_effect_chain\b/ | /dec\b/ | /destroy_effect_chain\b/ { "delete_effect_chain" } 
_find_effect_chains: /find_effect_chains\b/ | /fec\b/ { "find_effect_chains" } 
_find_user_effect_chains: /find_user_effect_chains\b/ | /fuec\b/ { "find_user_effect_chains" } 
_bypass_effects: /bypass_effects\b/ | /bypass\b/ | /bfx\b/ { "bypass_effects" } 
_bring_back_effects: /bring_back_effects\b/ | /restore_effects\b/ | /bbfx\b/ { "bring_back_effects" } 
_new_effect_profile: /new_effect_profile\b/ | /nep\b/ { "new_effect_profile" } 
_apply_effect_profile: /apply_effect_profile\b/ | /aep\b/ { "apply_effect_profile" } 
_destroy_effect_profile: /destroy_effect_profile\b/ { "destroy_effect_profile" } 
_list_effect_profiles: /list_effect_profiles\b/ | /lep\b/ { "list_effect_profiles" } 
_show_effect_profiles: /show_effect_profiles\b/ | /sepr\b/ { "show_effect_profiles" } 
_full_effect_profiles: /full_effect_profiles\b/ | /fep\b/ { "full_effect_profiles" } 
_cache_track: /cache_track\b/ | /cache\b/ | /ct\b/ | /bounce\b/ | /freeze\b/ { "cache_track" } 
_uncache_track: /uncache_track\b/ | /uncache\b/ | /unc\b/ { "uncache_track" } 
_do_script: /do_script\b/ | /do\b/ { "do_script" } 
_scan: /scan\b/ { "scan" } 
_add_fade: /add_fade\b/ | /afd\b/ | /fade\b/ { "add_fade" } 
_remove_fade: /remove_fade\b/ | /rfd\b/ { "remove_fade" } 
_list_fade: /list_fade\b/ | /lfd\b/ { "list_fade" } 
_add_comment: /add_comment\b/ | /comment\b/ | /ac\b/ { "add_comment" } 
_remove_comment: /remove_comment\b/ | /rc\b/ { "remove_comment" } 
_show_comment: /show_comment\b/ | /sc\b/ { "show_comment" } 
_show_comments: /show_comments\b/ | /sca\b/ { "show_comments" } 
_add_version_comment: /add_version_comment\b/ | /avc\b/ { "add_version_comment" } 
_remove_version_comment: /remove_version_comment\b/ | /rvc\b/ { "remove_version_comment" } 
_show_version_comment: /show_version_comment\b/ | /svc\b/ { "show_version_comment" } 
_show_version_comments_all: /show_version_comments_all\b/ | /svca\b/ { "show_version_comments_all" } 
_set_system_version_comment: /set_system_version_comment\b/ | /ssvc\b/ { "set_system_version_comment" } 
_midish_command: /midish_command\b/ | /m\b/ { "midish_command" } 
_midish_mode_on: /midish_mode_on\b/ | /mmo\b/ { "midish_mode_on" } 
_midish_mode_off: /midish_mode_off\b/ | /mmx\b/ { "midish_mode_off" } 
_midish_mode_off_ready_to_play: /midish_mode_off_ready_to_play\b/ | /mmxrp\b/ { "midish_mode_off_ready_to_play" } 
_midish_mode_off_ready_to_record: /midish_mode_off_ready_to_record\b/ | /mmxrr\b/ { "midish_mode_off_ready_to_record" } 
_new_edit: /new_edit\b/ | /ned\b/ { "new_edit" } 
_set_edit_points: /set_edit_points\b/ | /sep\b/ { "set_edit_points" } 
_list_edits: /list_edits\b/ | /led\b/ { "list_edits" } 
_select_edit: /select_edit\b/ | /sed\b/ { "select_edit" } 
_end_edit_mode: /end_edit_mode\b/ | /eem\b/ { "end_edit_mode" } 
_destroy_edit: /destroy_edit\b/ { "destroy_edit" } 
_preview_edit_in: /preview_edit_in\b/ | /pei\b/ { "preview_edit_in" } 
_preview_edit_out: /preview_edit_out\b/ | /peo\b/ { "preview_edit_out" } 
_play_edit: /play_edit\b/ | /ped\b/ { "play_edit" } 
_record_edit: /record_edit\b/ | /red\b/ { "record_edit" } 
_edit_track: /edit_track\b/ | /et\b/ { "edit_track" } 
_host_track_alias: /host_track_alias\b/ | /hta\b/ { "host_track_alias" } 
_host_track: /host_track\b/ | /ht\b/ { "host_track" } 
_version_mix_track: /version_mix_track\b/ | /vmt\b/ { "version_mix_track" } 
_play_start_mark: /play_start_mark\b/ | /psm\b/ { "play_start_mark" } 
_rec_start_mark: /rec_start_mark\b/ | /rsm\b/ { "rec_start_mark" } 
_rec_end_mark: /rec_end_mark\b/ | /rem\b/ { "rec_end_mark" } 
_set_play_start_mark: /set_play_start_mark\b/ | /spsm\b/ { "set_play_start_mark" } 
_set_rec_start_mark: /set_rec_start_mark\b/ | /srsm\b/ { "set_rec_start_mark" } 
_set_rec_end_mark: /set_rec_end_mark\b/ | /srem\b/ { "set_rec_end_mark" } 
_disable_edits: /disable_edits\b/ | /ded\b/ { "disable_edits" } 
_merge_edits: /merge_edits\b/ | /med\b/ { "merge_edits" } 
_explode_track: /explode_track\b/ { "explode_track" } 
_move_to_bus: /move_to_bus\b/ | /mtb\b/ { "move_to_bus" } 
_promote_version_to_track: /promote_version_to_track\b/ | /pvt\b/ { "promote_version_to_track" } 
_read_user_customizations: /read_user_customizations\b/ | /ruc\b/ { "read_user_customizations" } 
_limit_run_time: /limit_run_time\b/ | /lr\b/ { "limit_run_time" } 
_limit_run_time_off: /limit_run_time_off\b/ | /lro\b/ { "limit_run_time_off" } 
_offset_run: /offset_run\b/ | /ofr\b/ { "offset_run" } 
_offset_run_off: /offset_run_off\b/ | /ofro\b/ { "offset_run_off" } 
_view_waveform: /view_waveform\b/ | /wview\b/ { "view_waveform" } 
_edit_waveform: /edit_waveform\b/ | /wedit\b/ { "edit_waveform" } 
_rerecord: /rerecord\b/ | /rerec\b/ { "rerecord" } 
_analyze_level: /analyze_level\b/ | /anl\b/ { "analyze_level" } 
_for: /for\b/ { "for" } 
_git: /git\b/ { "git" } 
_edit_rec_setup_hook: /edit_rec_setup_hook\b/ | /ersh\b/ { "edit_rec_setup_hook" } 
_edit_rec_cleanup_hook: /edit_rec_cleanup_hook\b/ | /erch\b/ { "edit_rec_cleanup_hook" } 
_remove_fader_effect: /remove_fader_effect\b/ | /rffx\b/ { "remove_fader_effect" } 
_rename_track: /rename_track\b/ { "rename_track" } 
_new_sequence: /new_sequence\b/ | /nsq\b/ { "new_sequence" } 
_select_sequence: /select_sequence\b/ | /slsq\b/ { "select_sequence" } 
_list_sequences: /list_sequences\b/ | /lsq\b/ { "list_sequences" } 
_show_sequence: /show_sequence\b/ | /ssq\b/ { "show_sequence" } 
_append_to_sequence: /append_to_sequence\b/ | /asq\b/ { "append_to_sequence" } 
_insert_in_sequence: /insert_in_sequence\b/ | /isq\b/ { "insert_in_sequence" } 
_remove_from_sequence: /remove_from_sequence\b/ | /rsq\b/ { "remove_from_sequence" } 
_delete_sequence: /delete_sequence\b/ | /dsq\b/ { "delete_sequence" } 
_add_spacer: /add_spacer\b/ | /asp\b/ { "add_spacer" } 
_convert_to_sequence: /convert_to_sequence\b/ | /csq\b/ { "convert_to_sequence" } 
_merge_sequence: /merge_sequence\b/ | /msq\b/ { "merge_sequence" } 
_snip: /snip\b/ { "snip" } 
_compose: /compose\b/ | /compose_sequence\b/ | /compose_into_sequence\b/ { "compose" } 
_undo: /undo\b/ { "undo" } 
_redo: /redo\b/ { "redo" } 
_show_head_commit: /show_head_commit\b/ | /show_head\b/ | /last_command\b/ | /last\b/ { "show_head_commit" } 
_eager: /eager\b/ { "eager" } 
_new_engine: /new_engine\b/ | /neg\b/ { "new_engine" } 
_select_engine: /select_engine\b/ | /seg\b/ { "select_engine" } 
_set_track_engine_group: /set_track_engine_group\b/ | /steg\b/ { "set_track_engine_group" } 
_set_bus_engine_group: /set_bus_engine_group\b/ | /sbeg\b/ { "set_bus_engine_group" } 
_select_submix: /select_submix\b/ | /ssm\b/ { "select_submix" } 
_trim_submix: /trim_submix\b/ | /trim\b/ | /tsm\b/ { "trim_submix" } 
_nickname_effect: /nickname_effect\b/ | /nfx\b/ | /nick\b/ { "nickname_effect" } 
_delete_nickname_definition: /delete_nickname_definition\b/ | /dnd\b/ { "delete_nickname_definition" } 
_remove_nickname: /remove_nickname\b/ | /rnick\b/ { "remove_nickname" } 
_list_nickname_definitions: /list_nickname_definitions\b/ | /lnd\b/ { "list_nickname_definitions" } 
_set_effect_name: /set_effect_name\b/ | /sen\b/ { "set_effect_name" } 
_set_effect_surname: /set_effect_surname\b/ | /ses\b/ { "set_effect_surname" } 
_remove_effect_name: /remove_effect_name\b/ | /ren\b/ { "remove_effect_name" } 
_remove_effect_surname: /remove_effect_surname\b/ | /res\b/ { "remove_effect_surname" } 
_select_track: /select_track\b/ { "select_track" } 
@@ hotkey_grammar
command: set_current_effect
command: set_stepsize
command: set_jumpsize
command: set_parameter
command: cancel
cancel: /.+Escape/
foo: /./
set_current_effect: 'f' effect_id 'Enter' {Audio::Nama::set_current_op($item{effect_id}) }
effect_id: lower_case_effect_id { $return = uc $item{lower_case_effect_id} }
lower_case_effect_id: /[a-z]+/
set_stepsize: 'm' digit  { Audio::Nama::set_current_stepsize(10**$item{digit})}
set_stepsize: 'm-' digit { Audio::Nama::set_current_stepsize(10**-$item{digit})}
set_parameter: '=' value 'Enter' {Audio::Nama::set_parameter_value($item{value})}
set_jumpsize: 'j' value 'Enter' {$Audio::Nama::text->{hotkey_playback_jumpsize} = $item{value}}
digit: /\d/
value: /[+-]?([\d_]+(\.\d*)?|\.\d+)([eE][+-]?\d+)?/

@@ ecasound_chain_operator_hints_yml
---
-
  code: ea
  count: 1
  display: scale
  name: Volume
  params:
    -
      begin: 0
      default: 100
      end: 600
      name: "Level %"
      resolution: 0
-
  code: eadb
  count: 1
  display: scale
  name: Volume
  params:
    -
      begin: -40 
      default: 0
      end: 60
      name: "Level db"
      resolution: 0.5
-
  code: epp
  count: 1
  display: scale
  name: Pan
  params:
    -
      begin: 0
      default: 50
      end: 100
      name: "Level %"
      resolution: 0
-
  code: eal
  count: 1
  display: scale
  name: Limiter
  params:
    -
      begin: 0
      default: 100
      end: 100
      name: "Limit %"
      resolution: 0
-
  code: ec
  count: 2
  display: scale
  name: Compressor
  params:
    -
      begin: 0
      default: 1
      end: 1
      name: "Compression Rate (Db)"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Threshold %"
      resolution: 0
-
  code: eca
  count: 4
  display: scale
  name: "Advanced Compressor"
  params:
    -
      begin: 0
      default: 69
      end: 100
      name: "Peak Level %"
      resolution: 0
    -
      begin: 0
      default: 2
      end: 5
      name: "Release Time (Seconds)"
      resolution: 0
    -
      begin: 0
      default: 0.5
      end: 1
      name: "Fast Compressor Rate"
      resolution: 0
    -
      begin: 0
      default: 1
      end: 1
      name: "Compressor Rate (Db)"
      resolution: 0
-
  code: enm
  count: 5
  display: scale
  name: "Noise Gate"
  params:
    -
      begin: 0
      default: 100
      end: 100
      name: "Threshold Level %"
      resolution: 0
    -
      begin: 0
      default: 200
      end: 2000
      name: "Pre Hold Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 200
      end: 2000
      name: "Attack Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 200
      end: 2000
      name: "Post Hold Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 200
      end: 2000
      name: "Release Time (ms)"
      resolution: 0
-
  code: ef1
  count: 2
  display: scale
  name: "Resonant Bandpass Filter"
  params:
    -
      begin: 0
      default: 0
      end: 20000
      name: "Center Frequency (Hz)"
      resolution: 0
    -
      begin: 0
      default: 0
      end: 2000
      name: "Width (Hz)"
      resolution: 0
-
  code: ef3
  count: 3
  display: scale
  name: "Resonant Lowpass Filter"
  params:
    -
      begin: 0
      default: 0
      end: 5000
      name: "Cutoff Frequency (Hz)"
      resolution: 0
    -
      begin: 0
      default: 0
      end: 2
      name: Resonance
      resolution: 0
    -
      begin: 0
      default: 0
      end: 1
      name: Gain
      resolution: 0
-
  code: efa
  count: 2
  display: scale
  name: "Allpass Filter"
  params:
    -
      begin: 0
      default: 0
      end: 10000
      name: "Delay Samples"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Feedback %"
      resolution: 0
-
  code: efb
  count: 2
  display: scale
  name: "Bandpass Filter"
  params:
    -
      begin: 0
      default: 11000
      end: 11000
      name: "Center Frequency (Hz)"
      resolution: 0
    -
      begin: 0
      default: 22000
      end: 22000
      name: "Width (Hz)"
      resolution: 0
-
  code: efh
  count: 1
  display: scale
  name: "Highpass Filter"
  params:
    -
      begin: 10000
      default: 10000
      end: 22000
      name: "Cutoff Frequency (Hz)"
      resolution: 0
-
  code: efl
  count: 1
  display: scale
  name: "Lowpass Filter"
  params:
    -
      begin: 0
      default: 0
      end: 10000
      name: "Cutoff Frequency (Hz)"
      resolution: 0
-
  code: efr
  count: 2
  display: scale
  name: "Bandreject Filter"
  params:
    -
      begin: 0
      default: 11000
      end: 11000
      name: "Center Frequency (Hz)"
      resolution: 0
    -
      begin: 0
      default: 22000
      end: 22000
      name: "Width (Hz)"
      resolution: 0
-
  code: efs
  count: 2
  display: scale
  name: "Resonator Filter"
  params:
    -
      begin: 0
      default: 11000
      end: 11000
      name: "Center Frequency (Hz)"
      resolution: 0
    -
      begin: 0
      default: 22000
      end: 22000
      name: "Width (Hz)"
      resolution: 0
-
  code: etd
  count: 5
  display: scale
  name: Delay
  params:
    -
      begin: 0
      default: 200
      end: 2000
      name: "Delay Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 0
      end: 2
      name: "Surround Mode (Normal, Surround St., Spread)"
      resolution: 1
    -
      begin: 0
      default: 50
      end: 100
      name: "Number of Delays"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Mix %"
      resolution: 0
    -
      begin: 0
      default: 0
      end: 100
      name: "Feedback %"
      resolution: 0
-
  code: etc
  count: 4
  display: scale
  name: Chorus
  params:
    -
      begin: 0
      default: 200
      end: 2000
      name: "Delay Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 500
      end: 10000
      name: "Variance Time Samples"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Feedback %"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "LFO Frequency (Hz)"
      resolution: 0
-
  code: etr
  count: 3
  display: scale
  name: Reverb
  params:
    -
      begin: 0
      default: 200
      end: 2000
      name: "Delay Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 0
      end: 1
      name: "Surround Mode (0=Normal, 1=Surround)"
      resolution: 1
    -
      begin: 0
      default: 50
      end: 100
      name: "Feedback %"
      resolution: 0
-
  code: ete
  count: 3
  display: scale
  name: "Advanced Reverb"
  params:
    -
      begin: 0
      default: 10
      end: 100
      name: "Room Size (Meters)"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Feedback %"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Wet %"
      resolution: 0
-
  code: etf
  count: 1
  display: scale
  name: "Fake Stereo"
  params:
    -
      begin: 0
      default: 40
      end: 500
      name: "Delay Time (ms)"
      resolution: 0
-
  code: etl
  count: 4
  display: scale
  name: Flanger
  params:
    -
      begin: 0
      default: 200
      end: 1000
      name: "Delay Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 200
      end: 10000
      name: "Variance Time Samples"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Feedback %"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "LFO Frequency (Hz)"
      resolution: 0
-
  code: etm
  count: 3
  display: scale
  name: "Multitap Delay"
  params:
    -
      begin: 0
      default: 200
      end: 2000
      name: "Delay Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 20
      end: 100
      name: "Number of Delays"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Mix %"
      resolution: 0
-
  code: etp
  count: 4
  display: scale
  name: Phaser
  params:
    -
      begin: 0
      default: 200
      end: 2000
      name: "Delay Time (ms)"
      resolution: 0
    -
      begin: 0
      default: 100
      end: 10000
      name: "Variance Time Samples"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "Feedback %"
      resolution: 0
    -
      begin: 0
      default: 50
      end: 100
      name: "LFO Frequency (Hz)"
      resolution: 0
-
  code: pn:metronome
  count: 1
  display: scale
  name: Metronome
  params:
    -
      begin: 30
      default: 120
      end: 300
      name: BPM
      resolution: 1
...
;
@@ default_namarc
#
#         Nama Configuration file
#
#         This file has been auto-generated by Nama
#         It will not be overwritten, so edit it as you like.
#
#         Notes
#
#        - The format of this file is YAML, preprocessed to allow
#           comments.
#
#        - A value _must_ be supplied for each 'leaf' field.
#          For example "mixer_out_format: cd-stereo"
#
#        - A value must _not_ be supplied for nodes, i.e.
#          'device:'. The value for 'device' is the entire indented
#          data structure that follows in subsequent lines.
#
#        - white space *is* significant. Two spaces indent is
#          required for each sublevel.
#
#        - You may use the tilde symbol '~' to represent a null (undef) value
#          For example "execute_on_project_load: ~"
#
#         - This file is distinct from .ecasoundrc (which in
#           general you will not need to run Nama.)


# project root directory

# all project directories (or their symlinks) will live here

project_root: ~                  # replaced during first run

# define abbreviations

abbreviations:  
  24-mono: s24_le,1,frequency
  24-stereo: s24_le,2,frequency,i
  cd-mono: s16_le,1,44100
  cd-stereo: s16_le,2,44100,i
  frequency: 44100

# define audio devices

devices: 
  jack:
    signal_format: f32_le,N,frequency # do not change this
  consumer:
    ecasound_id: alsa,default
    input_format: cd-stereo
    output_format: cd-stereo
    hardware_latency: 0
  multi:
    ecasound_id: alsa,ice1712
    input_format: s32_le,12,frequency
    output_format: s32_le,10,frequency
    hardware_latency: 0
  null:
    ecasound_id: null
    output_format: ~

# ALSA soundcard device assignments and formats

alsa_capture_device: consumer       # for ALSA/OSS
alsa_playback_device: consumer      # for ALSA/OSS
mixer_out_format: cd-stereo         # for ALSA/OSS

# soundcard_channels: 10            # input/output channel selection range (GUI)

# audio file format templates

mix_to_disk_format: s16_le,N,frequency,i
raw_to_disk_format: s16_le,N,frequency,i
cache_to_disk_format: s16_le,N,frequency,i

mixdown_encodings: mp3 ogg

sample_rate: frequency

realtime_profile: nonrealtime # other choices: realtime or auto

# The buffer size settings below apply only when JACK is *not* used
ecasound_buffersize:
  realtime:
    default: 256
  nonrealtime:
    default: 1024
ecasound_globals:
  common: -z:mixmode,sum -G:jack,Nama,send
  realtime: -z:db,100000 -z:nointbuf 
  nonrealtime: -z:nodb -z:intbuf

# ecasound_tcp_port: 2868  

# WAVs recorded at the same time get the same numeric suffix

use_group_numbering: 1

# Enable pressing SPACE to start/stop transport (in terminal, cursor in column 1)

press_space_to_start_transport: 1

# commands to execute each time a project is loaded

execute_on_project_load: ~

volume_control_operator: eadb # must be 'ea' or 'eadb'

# beep PC speaker on command error

# beep_command: beep -f 350 -l 700

# hotkey_beep: beep -f 250 -l 200

# effects for use in mastering mode

eq: Parametric1 1 0 0 40 1 0 0 200 1 0 0 600 1 0 0 3300 1 0

low_pass: lowpass_iir 106 2

mid_pass: bandpass_iir 520 800 2

high_pass: highpass_iir 1030 2

compressor: sc4 0 3 16 0 1 3.25 0

spatialiser: matrixSpatialiser 0

limiter: tap_limiter 0 0

hotkeys:
  Escape: exit_hotkey_mode
  Insert: previous_track
  Delete: next_track
  Home: previous_effect
  End: next_effect
  PageUp: previous_param
  PageDown: next_param
  Left: previous_param
  Right: next_param
  Up: increment_param
  Down: decrement_param
  j: decrement_param
  k: increment_param
  h: previous_param
  l: next_param
  a: previous_track
  s: previous_effect
  d: next_effect
  f: next_track
  i: previous_track
  o: next_track
  I: previous_effect
  O: next_effect
  Space: toggle_transport

alias:
  command:
    mbs: move_to_bus
    pcv: promote_current_version
    djp: disable_jack_polling
  effect:
    reverb: gverb
# end

@@ custom_pl
### customize.pl - user code

# test this by typing:
#
#     perl customize.pl
#
# or, if you are running from your build directory, e.g.
#
#     perl -I ~/build/nama/lib customize.pl

use Modern::Perl;
use Audio::Nama::Globals qw(:all);

my @user_customization = (

prompt => sub { 
	no warnings 'uninitialized';
	join ' ', 'nama', git_branch_display(), bus_track_display(), '> ' 
},

## user defined commands

commands => 
	{
		# usage: greet <name> <adjective>
		greet => sub { 
				my ($name,$adjective) = @_;
				pager("Hello $name! You look $adjective today!!");
		},
		disable_jack_polling => sub{ $project->{events}->{poll_jack} = undef },

		promote_current_version => sub {
				my $v = $this_track->monitor_version;
				promote_version_to_track($this_track, $v);
		},

	},

);

@@ fake_jack_lsp
system:capture_1
   alsa_pcm:capture_1
	properties: output,can-monitor,physical,terminal,
system:capture_2
   alsa_pcm:capture_2
	properties: output,can-monitor,physical,terminal,
system:capture_3
   alsa_pcm:capture_3
	properties: output,can-monitor,physical,terminal,
system:capture_4
   alsa_pcm:capture_4
	properties: output,can-monitor,physical,terminal,
system:capture_5
   alsa_pcm:capture_5
	properties: output,can-monitor,physical,terminal,
system:capture_6
   alsa_pcm:capture_6
	properties: output,can-monitor,physical,terminal,
system:capture_7
   alsa_pcm:capture_7
	properties: output,can-monitor,physical,terminal,
system:capture_8
   alsa_pcm:capture_8
	properties: output,can-monitor,physical,terminal,
system:capture_9
   alsa_pcm:capture_9
	properties: output,can-monitor,physical,terminal,
system:capture_10
   alsa_pcm:capture_10
	properties: output,can-monitor,physical,terminal,
system:capture_11
   alsa_pcm:capture_11
	properties: output,can-monitor,physical,terminal,
system:capture_12
   alsa_pcm:capture_12
	properties: output,can-monitor,physical,terminal,
system:playback_1
   alsa_pcm:playback_1
	properties: input,physical,terminal,
system:playback_2
   alsa_pcm:playback_2
	properties: input,physical,terminal,
system:playback_3
   alsa_pcm:playback_3
	properties: input,physical,terminal,
system:playback_4
   alsa_pcm:playback_4
	properties: input,physical,terminal,
system:playback_5
   alsa_pcm:playback_5
	properties: input,physical,terminal,
system:playback_6
   alsa_pcm:playback_6
	properties: input,physical,terminal,
system:playback_7
   alsa_pcm:playback_7
	properties: input,physical,terminal,
system:playback_8
   alsa_pcm:playback_8
	properties: input,physical,terminal,
system:playback_9
   alsa_pcm:playback_9
	properties: input,physical,terminal,
system:playback_10
   alsa_pcm:playback_10
	properties: input,physical,terminal,
Horgand:out_1
        properties: output,terminal,
Horgand:out_2
        properties: output,terminal,
fluidsynth:left
	properties: output,
fluidsynth:right
	properties: output,
ecasound:out_1
	properties: output,
ecasound:out_2
	properties: output,
jconvolver:out_1
	properties: output,
jconvolver:out_2
	properties: output,
jconvolver:in_1
	properties: input,
jconvolver:in_2
	properties: input,
LinuxSampler:0
	properties: output,
LinuxSampler:1
	properties: output,
beatrix-0:output-0
	properties: output,
beatrix-0:output-1
	properties: output,

@@ fake_lv2_register
1. Calf Compressor
	-elv2:http://calf.sourceforge.net/plugins/Compressor,'Threshold','Ratio','
... Attack','Release','Makeup Gain','Knee','Detection','Stereo
... Link','A-weighting','Compression','Peak Output','0dB','Bypass'
2. Calf Filter
	-elv2:http://calf.sourceforge.net/plugins/Filter,'Frequency','Resonance','
... Mode','Inertia'
3. Calf Filterclavier
	-elv2:http://calf.sourceforge.net/plugins/Filterclavier,'Transpose','Detun
... e','Max. Resonance','Mode','Portamento time'
4. Calf Flanger
	-elv2:http://calf.sourceforge.net/plugins/Flanger,'Minimum
... delay','Modulation depth','Modulation rate','Feedback','Stereo
... phase','Reset','Amount','Dry Amount'
5. Calf Monosynth
	-elv2:http://calf.sourceforge.net/plugins/Monosynth,'Osc1 Wave','Osc2
... Wave','O1<>2 Detune','Osc 2 transpose','Phase mode','O1<>2
... Mix','Filter','Cutoff','Resonance','Separation','Env->Cutoff','Env->Res'
... ,'Env->Amp','Attack','Decay','Sustain','Release','Key Follow','Legato
... Mode','Portamento','Vel->Filter','Vel->Amp','Volume','PBend Range'
6. Calf MultiChorus
	-elv2:http://calf.sourceforge.net/plugins/MultiChorus,'Minimum
... delay','Modulation depth','Modulation rate','Stereo
... phase','Voices','Inter-voice phase','Amount','Dry Amount','Center Frq
... 1','Center Frq 2','Q'
7. Calf Phaser
	-elv2:http://calf.sourceforge.net/plugins/Phaser,'Center
... Freq','Modulation depth','Modulation rate','Feedback','#
... Stages','Stereo phase','Reset','Amount','Dry Amount'
8. Calf Reverb
	-elv2:http://calf.sourceforge.net/plugins/Reverb,'Decay time','High Frq
... Damp','Room size','Diffusion','Wet Amount','Dry Amount','Pre
... Delay','Bass Cut','Treble Cut'
9. Calf Rotary Speaker
	-elv2:http://calf.sourceforge.net/plugins/RotarySpeaker,'Speed Mode','Tap
... Spacing','Tap Offset','Mod Depth','Treble Motor','Bass Motor','Mic
... Distance','Reflection'
10. Calf Vintage Delay
	-elv2:http://calf.sourceforge.net/plugins/VintageDelay,'Tempo','Subdivide'
... ,'Time L','Time R','Feedback','Amount','Mix mode','Medium','Dry Amount'
11. IR
	-elv2:http://factorial.hu/plugins/lv2/ir,'Reverse
... IR','Predelay','Attack','Attack
... time','Envelope','Length','Stretch','Stereo width in','Stereo width
... IR','Autogain','Dry','Dry gain','Wet','Wet
... gain','FileHash0','FileHash1','FileHash2','Dry L meter','Dry R
... meter','Wet L meter','Wet R meter','Latency'
12. Aliasing
	-elv2:http://plugin.org.uk/swh-plugins/alias,'Aliasing level'
13. Allpass delay line, cubic spline interpolation
	-elv2:http://plugin.org.uk/swh-plugins/allpass_c,'Max Delay (s)','Delay
... Time (s)','Decay Time (s)'
14. Allpass delay line, linear interpolation
	-elv2:http://plugin.org.uk/swh-plugins/allpass_l,'Max Delay (s)','Delay
... Time (s)','Decay Time (s)'
15. Allpass delay line, noninterpolating
	-elv2:http://plugin.org.uk/swh-plugins/allpass_n,'Max Delay (s)','Delay
... Time (s)','Decay Time (s)'
16. AM pitchshifter
	-elv2:http://plugin.org.uk/swh-plugins/amPitchshift,'Pitch shift','Buffer
... size','latency'
17. Simple amplifier
	-elv2:http://plugin.org.uk/swh-plugins/amp,'Amps gain (dB)'
18. Analogue Oscillator
	-elv2:http://plugin.org.uk/swh-plugins/analogueOsc,'Waveform (1=sin,
... 2=tri, 3=squ, 4=saw)','Frequency (Hz)','Warmth','Instability'
19. Artificial latency
	-elv2:http://plugin.org.uk/swh-plugins/artificialLatency,'Delay
... (ms)','latency'
20. Auto phaser
	-elv2:http://plugin.org.uk/swh-plugins/autoPhaser,'Attack time
... (s)','Decay time (s)','Modulation depth','Feedback','Spread (octaves)'
21. Glame Bandpass Analog Filter
	-elv2:http://plugin.org.uk/swh-plugins/bandpass_a_iir,'Center Frequency
... (Hz)','Bandwidth (Hz)'
22. Glame Bandpass Filter
	-elv2:http://plugin.org.uk/swh-plugins/bandpass_iir,'Center Frequency
... (Hz)','Bandwidth (Hz)','Stages(2 poles per stage)'
23. Bode frequency shifter
	-elv2:http://plugin.org.uk/swh-plugins/bodeShifter,'Frequency
... shift','latency'
24. Bode frequency shifter (CV)
	-elv2:http://plugin.org.uk/swh-plugins/bodeShifterCV,'Base shift','Mix
... (-1=down, +1=up)','CV Attenuation','latency'
25. GLAME Butterworth Highpass
	-elv2:http://plugin.org.uk/swh-plugins/butthigh_iir,'Cutoff Frequency
... (Hz)','Resonance'
26. GLAME Butterworth Lowpass
	-elv2:http://plugin.org.uk/swh-plugins/buttlow_iir,'Cutoff Frequency
... (Hz)','Resonance'
27. Glame Butterworth X-over Filter
	-elv2:http://plugin.org.uk/swh-plugins/bwxover_iir,'Cutoff Frequency
... (Hz)','Resonance'
28. Chebyshev distortion
	-elv2:http://plugin.org.uk/swh-plugins/chebstortion,'Distortion'
29. Comb Filter
	-elv2:http://plugin.org.uk/swh-plugins/comb,'Band separation
... (Hz)','Feedback'
30. Comb Splitter
	-elv2:http://plugin.org.uk/swh-plugins/combSplitter,'Band separation (Hz)'
31. Comb delay line, cubic spline interpolation
	-elv2:http://plugin.org.uk/swh-plugins/comb_c,'Max Delay (s)','Delay Time
... (s)','Decay Time (s)'
32. Comb delay line, linear interpolation
	-elv2:http://plugin.org.uk/swh-plugins/comb_l,'Max Delay (s)','Delay Time
... (s)','Decay Time (s)'
33. Comb delay line, noninterpolating
	-elv2:http://plugin.org.uk/swh-plugins/comb_n,'Max Delay (s)','Delay Time
... (s)','Decay Time (s)'
34. Constant Signal Generator
	-elv2:http://plugin.org.uk/swh-plugins/const,'Signal amplitude'
35. Crossover distortion
	-elv2:http://plugin.org.uk/swh-plugins/crossoverDist,'Crossover
... amplitude','Smoothing'
36. DC Offset Remover
	-elv2:http://plugin.org.uk/swh-plugins/dcRemove,
37. Exponential signal decay
	-elv2:http://plugin.org.uk/swh-plugins/decay,'Decay Time (s)'
38. Decimator
	-elv2:http://plugin.org.uk/swh-plugins/decimator,'Bit depth','Sample rate
... (Hz)'
39. Declipper
	-elv2:http://plugin.org.uk/swh-plugins/declip,
40. Simple delay line, cubic spline interpolation
	-elv2:http://plugin.org.uk/swh-plugins/delay_c,'Max Delay (s)','Delay
... Time (s)'
41. Simple delay line, linear interpolation
	-elv2:http://plugin.org.uk/swh-plugins/delay_l,'Max Delay (s)','Delay
... Time (s)'
42. Simple delay line, noninterpolating
	-elv2:http://plugin.org.uk/swh-plugins/delay_n,'Max Delay (s)','Delay
... Time (s)'
43. Delayorama
	-elv2:http://plugin.org.uk/swh-plugins/delayorama,'Random seed','Input
... gain (dB)','Feedback (%)','Number of taps','First delay (s)','Delay
... range (s)','Delay change','Delay random (%)','Amplitude
... change','Amplitude random (%)','Dry/wet mix'
44. Diode Processor
	-elv2:http://plugin.org.uk/swh-plugins/diode,'Mode (0 for none, 1 for
... half wave, 2 for full wave)'
45. Audio Divider (Suboctave Generator)
	-elv2:http://plugin.org.uk/swh-plugins/divider,'Denominator'
46. DJ flanger
	-elv2:http://plugin.org.uk/swh-plugins/djFlanger,'LFO sync','LFO period
... (s)','LFO depth (ms)','Feedback (%)'
47. DJ EQ
	-elv2:http://plugin.org.uk/swh-plugins/dj_eq,'Lo gain (dB)','Mid gain
... (dB)','Hi gain (dB)','latency'
48. DJ EQ (mono)
	-elv2:http://plugin.org.uk/swh-plugins/dj_eq_mono,'Lo gain (dB)','Mid
... gain (dB)','Hi gain (dB)','latency'
49. Dyson compressor
	-elv2:http://plugin.org.uk/swh-plugins/dysonCompress,'Peak limit
... (dB)','Release time (s)','Fast compression ratio','Compression ratio'
50. Fractionally Addressed Delay Line
	-elv2:http://plugin.org.uk/swh-plugins/fadDelay,'Delay
... (seconds)','Feedback (dB)'
51. Fast Lookahead limiter
	-elv2:http://plugin.org.uk/swh-plugins/fastLookaheadLimiter,'Input gain
... (dB)','Limit (dB)','Release time (s)','Attenuation (dB)','latency'
52. Flanger
	-elv2:http://plugin.org.uk/swh-plugins/flanger,'Delay base (ms)','Max
... slowdown (ms)','LFO frequency (Hz)','Feedback'
53. FM Oscillator
	-elv2:http://plugin.org.uk/swh-plugins/fmOsc,'Waveform (1=sin, 2=tri,
... 3=squ, 4=saw)'
54. Foldover distortion
	-elv2:http://plugin.org.uk/swh-plugins/foldover,'Drive','Skew'
55. 4 x 4 pole allpass
	-elv2:http://plugin.org.uk/swh-plugins/fourByFourPole,'Frequency
... 1','Feedback 1','Frequency 2','Feedback 2','Frequency 3','Feedback
... 3','Frequency 4','Feedback 4'
56. Fast overdrive
	-elv2:http://plugin.org.uk/swh-plugins/foverdrive,'Drive level'
57. Frequency tracker
	-elv2:http://plugin.org.uk/swh-plugins/freqTracker,'Tracking speed'
58. Gate
	-elv2:http://plugin.org.uk/swh-plugins/gate,'LF key filter (Hz)','HF key
... filter (Hz)','Threshold (dB)','Attack (ms)','Hold (ms)','Decay
... (ms)','Range (dB)','Output select (-1 = key listen, 0 = gate, 1 =
... bypass)','Key level (dB)','Gate state'
59. Giant flange
	-elv2:http://plugin.org.uk/swh-plugins/giantFlange,'Double delay','LFO
... frequency 1 (Hz)','Delay 1 range (s)','LFO frequency 2 (Hz)','Delay 2
... range (s)','Feedback','Dry/Wet level'
60. Gong model
	-elv2:http://plugin.org.uk/swh-plugins/gong,'Inner damping','Outer
... damping','Mic position','Inner size 1','Inner stiffness 1 +','Inner
... stiffness 1 -','Inner size 2','Inner stiffness 2 +','Inner stiffness 2
... -','Inner size 3','Inner stiffness 3 +','Inner stiffness 3 -','Inner
... size 4','Inner stiffness 4 +','Inner stiffness 4 -','Outer size
... 1','Outer stiffness 1 +','Outer stiffness 1 -','Outer size 2','Outer
... stiffness 2 +','Outer stiffness 2 -','Outer size 3','Outer stiffness 3
... +','Outer stiffness 3 -','Outer size 4','Outer stiffness 4 +','Outer
... stiffness 4 -'
61. Gong beater
	-elv2:http://plugin.org.uk/swh-plugins/gongBeater,'Impulse gain
... (dB)','Strike gain (dB)','Strike duration (s)'
62. GVerb
	-elv2:http://plugin.org.uk/swh-plugins/gverb,'Roomsize (m)','Reverb time
... (s)','Damping','Input bandwidth','Dry signal level (dB)','Early
... reflection level (dB)','Tail level (dB)'
63. Hard Limiter
	-elv2:http://plugin.org.uk/swh-plugins/hardLimiter,'dB limit','Wet
... level','Residue level'
64. Harmonic generator
	-elv2:http://plugin.org.uk/swh-plugins/harmonicGen,'Fundamental
... magnitude','2nd harmonic magnitude','3rd harmonic magnitude','4th
... harmonic magnitude','5th harmonic magnitude','6th harmonic
... magnitude','7th harmonic magnitude','8th harmonic magnitude','9th
... harmonic magnitude','10th harmonic magnitude'
65. Hermes Filter
	-elv2:http://plugin.org.uk/swh-plugins/hermesFilter,'LFO1 freq
... (Hz)','LFO1 wave (0 = sin, 1 = tri, 2 = saw, 3 = squ, 4 = s&h)','LFO2
... freq (Hz)','LFO2 wave (0 = sin, 1 = tri, 2 = saw, 3 = squ, 4 =
... s&h)','Osc1 freq (Hz)','Osc1 wave (0 = sin, 1 = tri, 2 = saw, 3 = squ,
... 4 = noise)','Osc2 freq (Hz)','Osc2 wave (0 = sin, 1 = tri, 2 = saw, 3 =
... squ, 4 = noise)','Ringmod 1 depth (0=none, 1=AM, 2=RM)','Ringmod 2
... depth (0=none, 1=AM, 2=RM)','Ringmod 3 depth (0=none, 1=AM,
... 2=RM)','Osc1 gain (dB)','RM1 gain (dB)','Osc2 gain (dB)','RM2 gain
... (dB)','Input gain (dB)','RM3 gain (dB)','Xover lower freq','Xover upper
... freq','Dist1 drive','Dist2 drive','Dist3 drive','Filt1 type (0=none,
... 1=LP, 2=HP, 3=BP, 4=BR, 5=AP)','Filt1 freq','Filt1 q','Filt1
... resonance','Filt1 LFO1 level','Filt1 LFO2 level','Filt2 type (0=none,
... 1=LP, 2=HP, 3=BP, 4=BR, 5=AP)','Filt2 freq','Filt2 q','Filt2
... resonance','Filt2 LFO1 level','Filt2 LFO2 level','Filt3 type (0=none,
... 1=LP, 2=HP, 3=BP, 4=BR, 5=AP)','Filt3 freq','Filt3 q','Filt3
... resonance','Filt3 LFO1 level','Filt3 LFO2 level','Delay1 length
... (s)','Delay1 feedback','Delay1 wetness','Delay2 length (s)','Delay2
... feedback','Delay2 wetness','Delay3 length (s)','Delay3
... feedback','Delay3 wetness','Band 1 gain (dB)','Band 2 gain (dB)','Band
... 3 gain (dB)'
66. Glame Highpass Filter
	-elv2:http://plugin.org.uk/swh-plugins/highpass_iir,'Cutoff
... Frequency','Stages(2 poles per stage)'
67. Hilbert transformer
	-elv2:http://plugin.org.uk/swh-plugins/hilbert,'latency'
68. Non-bandlimited single-sample impulses
	-elv2:http://plugin.org.uk/swh-plugins/impulse_fc,'Frequency (Hz)'
69. Inverter
	-elv2:http://plugin.org.uk/swh-plugins/inv,
70. Karaoke
	-elv2:http://plugin.org.uk/swh-plugins/karaoke,'Vocal volume (dB)'
71. L/C/R Delay
	-elv2:http://plugin.org.uk/swh-plugins/lcrDelay,'L delay (ms)','L
... level','C delay (ms)','C level','R delay (ms)','R
... level','Feedback','High damp (%)','Low damp (%)','Spread','Dry/Wet
... level'
72. LFO Phaser
	-elv2:http://plugin.org.uk/swh-plugins/lfoPhaser,'LFO rate (Hz)','LFO
... depth','Feedback','Spread (octaves)'
73. Lookahead limiter
	-elv2:http://plugin.org.uk/swh-plugins/lookaheadLimiter,'Limit
... (dB)','Lookahead delay','Attenuation (dB)','latency'
74. Lookahead limiter (fixed latency)
	-elv2:http://plugin.org.uk/swh-plugins/lookaheadLimiterConst,'Limit
... (dB)','Lookahead time (s)','Attenuation (dB)','latency'
75. Glame Lowpass Filter
	-elv2:http://plugin.org.uk/swh-plugins/lowpass_iir,'Cutoff
... Frequency','Stages(2 poles per stage)'
76. LS Filter
	-elv2:http://plugin.org.uk/swh-plugins/lsFilter,'Filter type (0=LP, 1=BP,
... 2=HP)','Cutoff frequency (Hz)','Resonance'
77. Matrix: MS to Stereo
	-elv2:http://plugin.org.uk/swh-plugins/matrixMSSt,'Width'
78. Matrix Spatialiser
	-elv2:http://plugin.org.uk/swh-plugins/matrixSpatialiser,'Width'
79. Matrix: Stereo to MS
	-elv2:http://plugin.org.uk/swh-plugins/matrixStMS,
80. Multiband EQ
	-elv2:http://plugin.org.uk/swh-plugins/mbeq,'50Hz gain (low
... shelving)','100Hz gain','156Hz gain','220Hz gain','311Hz gain','440Hz
... gain','622Hz gain','880Hz gain','1250Hz gain','1750Hz gain','2500Hz
... gain','3500Hz gain','5000Hz gain','10000Hz gain','20000Hz
... gain','latency'
81. Modulatable delay
	-elv2:http://plugin.org.uk/swh-plugins/modDelay,'Base delay (s)'
82. Multivoice Chorus
	-elv2:http://plugin.org.uk/swh-plugins/multivoiceChorus,'Number of
... voices','Delay base (ms)','Voice separation (ms)','Detune (%)','LFO
... frequency (Hz)','Output attenuation (dB)'
83. Higher Quality Pitch Scaler
	-elv2:http://plugin.org.uk/swh-plugins/pitchScaleHQ,'Pitch
... co-efficient','latency'
84. Plate reverb
	-elv2:http://plugin.org.uk/swh-plugins/plate,'Reverb
... time','Damping','Dry/wet mix'
85. Pointer cast distortion
	-elv2:http://plugin.org.uk/swh-plugins/pointerCastDistortion,'Effect
... cutoff freq (Hz)','Dry/wet mix'
86. Rate shifter
	-elv2:http://plugin.org.uk/swh-plugins/rateShifter,'Rate'
87. Retro Flanger
	-elv2:http://plugin.org.uk/swh-plugins/retroFlange,'Average stall
... (ms)','Flange frequency (Hz)'
88. Reverse Delay (5s max)
	-elv2:http://plugin.org.uk/swh-plugins/revdelay,'Delay Time (s)','Dry
... Level (dB)','Wet Level (dB)','Feedback','Crossfade samples'
89. Ringmod with LFO
	-elv2:http://plugin.org.uk/swh-plugins/ringmod_1i1o1l,'Modulation depth
... (0=none, 1=AM, 2=RM)','Frequency (Hz)','Sine level','Triangle
... level','Sawtooth level','Square level'
90. Ringmod with two inputs
	-elv2:http://plugin.org.uk/swh-plugins/ringmod_2i1o,'Modulation depth
... (0=none, 1=AM, 2=RM)'
91. Barry's Satan Maximiser
	-elv2:http://plugin.org.uk/swh-plugins/satanMaximiser,'Decay time
... (samples)','Knee point (dB)'
92. SC1
	-elv2:http://plugin.org.uk/swh-plugins/sc1,'Attack time (ms)','Release
... time (ms)','Threshold level (dB)','Ratio (1:n)','Knee radius
... (dB)','Makeup gain (dB)'
93. SC2
	-elv2:http://plugin.org.uk/swh-plugins/sc2,'Attack time (ms)','Release
... time (ms)','Threshold level (dB)','Ratio (1:n)','Knee radius
... (dB)','Makeup gain (dB)'
94. SC3
	-elv2:http://plugin.org.uk/swh-plugins/sc3,'Attack time (ms)','Release
... time (ms)','Threshold level (dB)','Ratio (1:n)','Knee radius
... (dB)','Makeup gain (dB)','Chain balance'
95. SC4
	-elv2:http://plugin.org.uk/swh-plugins/sc4,'RMS/peak','Attack time
... (ms)','Release time (ms)','Threshold level (dB)','Ratio (1:n)','Knee
... radius (dB)','Makeup gain (dB)','Amplitude (dB)','Gain reduction (dB)'
96. SE4
	-elv2:http://plugin.org.uk/swh-plugins/se4,'RMS/peak','Attack time
... (ms)','Release time (ms)','Threshold level (dB)','Ratio (1:n)','Knee
... radius (dB)','Attenuation (dB)','Amplitude (dB)','Gain expansion (dB)'
97. Wave shaper
	-elv2:http://plugin.org.uk/swh-plugins/shaper,'Waveshape'
98. Signal sifter
	-elv2:http://plugin.org.uk/swh-plugins/sifter,'Sift size'
99. Sine + cosine oscillator
	-elv2:http://plugin.org.uk/swh-plugins/sinCos,'Base frequency
... (Hz)','Pitch offset'
100. Single band parametric
	-elv2:http://plugin.org.uk/swh-plugins/singlePara,'Gain (dB)','Frequency
... (Hz)','Bandwidth (octaves)'
101. Sinus wavewrapper
	-elv2:http://plugin.org.uk/swh-plugins/sinusWavewrapper,'Wrap degree'
102. Smooth Decimator
	-elv2:http://plugin.org.uk/swh-plugins/smoothDecimate,'Resample
... rate','Smoothing'
103. Mono to Stereo splitter
	-elv2:http://plugin.org.uk/swh-plugins/split,
104. Surround matrix encoder
	-elv2:http://plugin.org.uk/swh-plugins/surroundEncoder,
105. State Variable Filter
	-elv2:http://plugin.org.uk/swh-plugins/svf,'Filter type (0=none, 1=LP,
... 2=HP, 3=BP, 4=BR, 5=AP)','Filter freq','Filter Q','Filter resonance'
106. Tape Delay Simulation
	-elv2:http://plugin.org.uk/swh-plugins/tapeDelay,'Tape speed (inches/sec,
... 1=normal)','Dry level (dB)','Tap 1 distance (inches)','Tap 1 level
... (dB)','Tap 2 distance (inches)','Tap 2 level (dB)','Tap 3 distance
... (inches)','Tap 3 level (dB)','Tap 4 distance (inches)','Tap 4 level
... (dB)'
107. Transient mangler
	-elv2:http://plugin.org.uk/swh-plugins/transient,'Attack speed','Sustain
... time'
108. Triple band parametric with shelves
	-elv2:http://plugin.org.uk/swh-plugins/triplePara,'Low-shelving gain
... (dB)','Low-shelving frequency (Hz)','Low-shelving slope','Band 1 gain
... (dB)','Band 1 frequency (Hz)','Band 1 bandwidth (octaves)','Band 2 gain
... (dB)','Band 2 frequency (Hz)','Band 2 bandwidth (octaves)','Band 3 gain
... (dB)','Band 3 frequency (Hz)','Band 3 bandwidth
... (octaves)','High-shelving gain (dB)','High-shelving frequency
... (Hz)','High-shelving slope'
109. Valve saturation
	-elv2:http://plugin.org.uk/swh-plugins/valve,'Distortion
... level','Distortion character'
110. Valve rectifier
	-elv2:http://plugin.org.uk/swh-plugins/valveRect,'Sag level','Distortion'
111. VyNil (Vinyl Effect)
	-elv2:http://plugin.org.uk/swh-plugins/vynil,'Year','RPM','Surface
... warping','Crackle','Wear'
112. Wave Terrain Oscillator
	-elv2:http://plugin.org.uk/swh-plugins/waveTerrain,
113. Crossfade
	-elv2:http://plugin.org.uk/swh-plugins/xfade,'Crossfade'
114. Crossfade (4 outs)
	-elv2:http://plugin.org.uk/swh-plugins/xfade4,'Crossfade'
115. z-1
	-elv2:http://plugin.org.uk/swh-plugins/zm1,
116. TalentedHack
	-elv2:urn:jeremy.salwen:plugins:talentedhack,'Mix','Pull To In
... Tune','Smooth Pitch','Formant Correction','Formant Warp','Jump To Midi
... Input','Pitch Correct Midi Out','Quantize LFO','LFO Amplitude','LFO
... Rate (Hz)','LFO Shape','LFO Symmetry','Concert A (Hz)','Detect
... A','Detect A#','Detect B','Detect C','Detect C#','Detect D','Detect
... D#','Detect E','Detect F','Detect F#','Detect G','Detect G#','Output
... A','Output A#','Output B','Output C','Output C#','Output D','Output
... D#','Output E','Output F','Output F#','Output G','Output G#','Latency'

@@ fake_jack_latency
system:capture_1
        port latency = 1024 frames
        port playback latency = [ 0 0 ] frames
        port capture latency = [ 1024 1024 ] frames
system:capture_2
        port latency = 1024 frames
        port playback latency = [ 0 0 ] frames
        port capture latency = [ 1024 1024 ] frames
system:playback_1
        port latency = 2048 frames
        port playback latency = [ 2048 2048 ] frames
        port capture latency = [ 0 0 ] frames
system:playback_2
        port latency = 2048 frames
        port playback latency = [ 2048 2048 ] frames
        port capture latency = [ 0 0 ] frames
LinuxSampler:capture_1
        port latency = 1024 frames
        port playback latency = [ 256 256 ] frames
        port capture latency = [ 512 1024 ] frames
LinuxSampler:capture_2
        port latency = 1024 frames
        port playback latency = [ 256 256 ] frames
        port capture latency = [ 256 1024 ] frames
LinuxSampler:playback_1
        port latency = 2048 frames
        port playback latency = [ 2048 2048 ] frames
        port capture latency = [ 512 512 ] frames
LinuxSampler:playback_2
        port latency = 2048 frames
        port playback latency = [ 2048 2048 ] frames
        port capture latency = [ 512 512 ] frames

@@ midish_commands
tracklist
tracknew
trackdelete
trackrename
trackexists
trackaddev
tracksetcurfilt
trackgetcurfilt
trackcheck
trackcut
trackblank
trackinsert
trackcopy
trackquant
tracktransp
trackmerge
tracksetmute
trackgetmute
trackchanlist
trackinfo
channew
chanset
chandelete
chanrename
chanexists
changetch
changetdev
chanconfev
chanunconfev
chaninfo
chansetcurinput
changetcurinput
filtnew
filtdelete
filtrename
filtexists
filtreset
filtinfo
filtsetcurchan
filtgetcurchan
filtchgich
filtchgidev
filtswapich
filtswapidev
filtchgoch
filtchgodev
filtswapoch
filtswapodev
filtdevdrop
filtnodevdrop
filtdevmap
filtnodevmap
filtchandrop
filtnochandrop
filtchanmap
filtnochanmap
filtctldrop
filtnoctldrop
filtctlmap
filtnoctlmap
filtkeydrop
filtnokeydrop
filtkeymap
filtnokeymap
sysexnew
sysexdelete
sysexrename
sysexexists
sysexclear
sysexsetunit
sysexadd
sysexinfo
songidle
songplay
songrecord
sendraw
songsetcurquant
songgetcurquant
songsetcurpos
songgetcurpos
songsetcurlen
songgetcurlen
songsetcurtrack
songgetcurtrack
songsetcurfilt
songgetcurfilt
songsetcursysex
songgetcursysex
songsetcurchan
songgetcurchan
songsetcurinput
changetcurinput
songsetunit
songgetunit
songsetfactor
songgetfactor
songsettempo
songtimeins
songtimerm
songtimeinfo
songinfo
songsave
songload
songreset
songexportsmf
songimportsmf
devlist
devattach
devdetach
devsetmaster
devgetmaster
devsendrt
devticrate
devinfo
devixctl
devoxctl
ctlconf
ctlconfx
ctlconf
ctlinfo
metroswitch
metroconf
info
print
exec
debug
panic
let
proc

@@ default_palette_json
{
   "gui" : {
      "_nama_palette" : {
         "Capture" : "#f22c92f088d3",
         "ClockBackground" : "#998ca489b438",
         "ClockForeground" : "#000000000000",
         "GroupBackground" : "#998ca489b438",
         "GroupForeground" : "#000000000000",
         "MarkArmed" : "#d74a811f443f",
         "Mixdown" : "#bf67c5a1491f",
         "MonBackground" : "#9420a9aec871",
         "MonForeground" : "Black",
         "Mute" : "#a5a183828382",
         "OffBackground" : "#998ca489b438",
         "OffForeground" : "Black",
         "Play" : "#68d7aabf755c",
         "RecBackground" : "#d9156e866335",
         "RecForeground" : "Black",
         "SendBackground" : "#9ba79cbbcc8a",
         "SendForeground" : "Black",
         "SourceBackground" : "#f22c92f088d3",
         "SourceForeground" : "Black"
      },
      "_palette" : {
         "ew" : {
            "background" : "#d915cc1bc3cf",
            "foreground" : "black"
         },
         "mw" : {
            "activeBackground" : "#4e097822b438",
            "background" : "#c2c5d0b5e49a",
            "foreground" : "black"
         }
      }
   }
}

@@ banner
      ////////////////////////////////////////////////////////////////////
     /                                                                  /
    /    Nama multitrack recorder v. $VERSION (c)2008-2014 Joel Roth      /
   /                                                                  /
  /    Audio processing by Ecasound, courtesy of Kai Vehmanen        /
 /                                                                  /
////////////////////////////////////////////////////////////////////

Starting...